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

if (!PROJECT_ID || !LOCATION || !TARGET_POOL_NAME || !CURSOR_API_KEY) {
  console.error("FATAL: Missing required environment variables.");
  process.exit(1);
}

const workerPoolClient = new WorkerPoolsClient();

async function scaleCursorWorkers() {
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
    } else {
      console.log("Current state: 0 workers connected. Waiting for next cycle...");
      return;
    }

    console.log(`Current state: ${inUse} workers in use out of ${totalConnected} total connected.`);

    let desiredInstances = Math.ceil(inUse / TARGET_UTILIZATION);
    desiredInstances = Math.max(MIN_INSTANCES, Math.min(desiredInstances, MAX_INSTANCES));

    if (desiredInstances !== totalConnected) {
      console.log(
        `Scaling Worker Pool from ${totalConnected} to ${desiredInstances} instances...`,
      );
      await updateCloudRunWorkerPool(desiredInstances);
    } else {
      console.log("Utilization is stable. No scaling action required.");
    }
  } catch (error) {
    console.error("Error in scaling execution:", error);
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
