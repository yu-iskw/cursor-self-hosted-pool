# Contract tests for cursor-worker-pool naming and validation helpers.
# Execute from modules/cursor-worker-pool:
#   terraform test

variables {
  project_id = "test-project"
  region     = "us-central1"
  repository = {
    owner = "example-org"
    name  = "example-service"
  }
  environment = "development"
  image = {
    repository = "us-docker.pkg.dev/platform/cursor/worker"
    digest     = "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  }
  runtime_service_account_email = "cursor-runtime@test-project.iam.gserviceaccount.com"
  capacity = {
    instance_count = 1
    cpu            = "2"
    memory         = "4Gi"
  }
  network = {
    profile           = "restricted"
    network_id        = "projects/test/global/networks/n"
    subnetwork_id     = "projects/test/regions/us-central1/subnetworks/s"
    route_all_traffic = true
    approved_egress_control = {
      resource_id = "organizations/1/policies/egress"
      owner       = "platform-networking"
    }
  }
}

run "rejects_mutable_digest_format" {
  command = plan

  variables {
    image = {
      repository = "us-docker.pkg.dev/platform/cursor/worker"
      digest     = "latest"
    }
  }

  expect_failures = [
    var.image,
  ]
}
