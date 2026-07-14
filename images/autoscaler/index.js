const http = require("http");
const { WorkerPoolsClient } = require("@google-cloud/run").v2;

const CURSOR_API_KEY = process.env.CURSOR_API_KEY;
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT;
const LOCATION = process.env.CLOUD_RUN_LOCATION;
const TARGET_POOL_NAME = process.env.WORKER_SERVICE_NAME;

const TARGET_UTILIZATION = parseFloat(process.env.TARGET_UTILIZATION || "0.5");
const MIN_INSTANCES = parseInt(process.env.MIN_INSTANCES || "1", 10);
const MAX_INSTANCES = parseInt(process.env.MAX_INSTANCES || "50", 10);
const POLLING_INTERVAL_MS = parseInt(process.env.POLLING_INTERVAL_MS || "30000", 10);
const PORT = parseInt(process.env.PORT || "8080", 10);
const LOG_VERBOSE = process.env.LOG_VERBOSE === "1";

if (!PROJECT_ID || !LOCATION || !TARGET_POOL_NAME || !CURSOR_API_KEY) {
  console.error("FATAL: Missing required environment variables.");
  process.exit(1);
}

const workerPoolClient = new WorkerPoolsClient();
let cycleInFlight = false;

function logInfo(message) {
  if (LOG_VERBOSE) {
    console.log(message);
  }
}

async function getCurrentManualInstanceCount() {
  const workerPoolPath = workerPoolClient.workerPoolPath(PROJECT_ID, LOCATION, TARGET_POOL_NAME);
  const [pool] = await workerPoolClient.getWorkerPool({ name: workerPoolPath });
  return pool.scaling?.manualInstanceCount ?? 0;
}

async function scaleCursorWorkers() {
  if (cycleInFlight) {
    logInfo("Skipping poll; previous scaling cycle still in flight.");
    return;
  }
  cycleInFlight = true;

  try {
    const response = await fetch("https://api.cursor.com/v0/private-workers/summary", {
      method: "GET",
      headers: {
        Authorization: "Basic " + Buffer.from(`${CURSOR_API_KEY}:`).toString("base64"),
      },
    });

    if (!response.ok) {
      throw new Error(`Cursor API responded with status: ${response.status}`);
    }

    const summary = await response.json();
    const team = summary.teamSummary;
    const user = summary.userSummary;

    let inUse = 0;
    let totalConnected = 0;

    if (team && team.totalConnected > 0) {
      inUse = team.inUse;
      totalConnected = team.totalConnected;
    } else if (user && user.totalConnected > 0) {
      inUse = user.inUse;
      totalConnected = user.totalConnected;
    }

    let desiredInstances = Math.ceil(inUse / TARGET_UTILIZATION);
    desiredInstances = Math.max(MIN_INSTANCES, Math.min(desiredInstances, MAX_INSTANCES));
    if (totalConnected === 0) {
      logInfo(`Fleet reports 0 connected workers; targeting MIN_INSTANCES=${MIN_INSTANCES}.`);
    } else {
      logInfo(`Fleet: ${inUse} in use / ${totalConnected} connected.`);
    }

    const currentInstances = await getCurrentManualInstanceCount();
    if (desiredInstances === currentInstances) {
      logInfo(`Cloud Run already at ${currentInstances} instances. No scaling action.`);
      return;
    }

    console.log(
      `Scaling Worker Pool from ${currentInstances} to ${desiredInstances} (fleet connected=${totalConnected}, inUse=${inUse}).`,
    );
    await updateCloudRunWorkerPool(desiredInstances);
  } catch (error) {
    console.error("Error in scaling execution:", error);
  } finally {
    cycleInFlight = false;
  }
}

async function updateCloudRunWorkerPool(instanceCount) {
  const workerPoolPath = workerPoolClient.workerPoolPath(PROJECT_ID, LOCATION, TARGET_POOL_NAME);

  const request = {
    workerPool: {
      name: workerPoolPath,
      scaling: {
        manualInstanceCount: instanceCount,
      },
    },
    updateMask: {
      paths: ["scaling.manual_instance_count"],
    },
  };

  const [operation] = await workerPoolClient.updateWorkerPool(request);
  await operation.promise();
  console.log(`Successfully patched Cloud Run Worker Pool to ${instanceCount} workers.`);
}

http
  .createServer((req, res) => {
    if (req.url === "/healthz" || req.url === "/readyz") {
      res.writeHead(200, { "Content-Type": "text/plain" });
      res.end("ok");
      return;
    }
    res.writeHead(404);
    res.end();
  })
  .listen(PORT, () => {
    console.log(`Health server listening on ${PORT}`);
  });

console.log(`Starting autoscaler loop (interval ${POLLING_INTERVAL_MS}ms)`);
scaleCursorWorkers();
setInterval(scaleCursorWorkers, POLLING_INTERVAL_MS);
