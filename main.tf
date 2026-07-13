locals {
  service_account_email = var.create_service_account ? google_service_account.worker[0].email : var.service_account_email
  service_account_id    = coalesce(var.service_account_id, substr("${var.name}-worker", 0, 30))

  required_services = toset([
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = var.manage_project_services ? local.required_services : toset([])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "worker" {
  count = var.create_service_account ? 1 : 0

  project      = var.project_id
  account_id   = local.service_account_id
  display_name = "Cursor self-hosted worker pool ${var.name}"
  description  = "Dedicated runtime identity for Cursor self-hosted workers."
}

resource "google_secret_manager_secret_iam_member" "cursor_api_key" {
  project   = var.project_id
  secret_id = var.cursor_api_key_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.service_account_email}"
}

resource "google_cloud_run_v2_worker_pool" "this" {
  project             = var.project_id
  location            = var.region
  name                = var.name
  deletion_protection = var.deletion_protection
  labels              = merge({ managed-by = "terraform", workload = "cursor-agent" }, var.labels)

  scaling {
    manual_instance_count = var.worker_count
  }

  template {
    service_account       = local.service_account_email
    execution_environment = var.execution_environment

    dynamic "vpc_access" {
      for_each = var.vpc_access == null ? [] : [var.vpc_access]
      content {
        egress = vpc_access.value.egress

        dynamic "network_interfaces" {
          for_each = vpc_access.value.network_interfaces
          content {
            network    = network_interfaces.value.network
            subnetwork = network_interfaces.value.subnetwork
            tags       = network_interfaces.value.tags
          }
        }
      }
    }

    containers {
      image   = var.container_image
      command = var.command
      args    = var.args

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      env {
        name = var.cursor_api_key_environment_name
        value_source {
          secret_key_ref {
            secret  = var.cursor_api_key_secret_id
            version = var.cursor_api_key_secret_version
          }
        }
      }

      dynamic "env" {
        for_each = var.environment
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  depends_on = [
    google_project_service.required,
    google_secret_manager_secret_iam_member.cursor_api_key,
  ]

  lifecycle {
    precondition {
      condition     = var.create_service_account || var.service_account_email != null
      error_message = "service_account_email is required when create_service_account is false."
    }

    precondition {
      condition     = !contains(keys(var.environment), var.cursor_api_key_environment_name)
      error_message = "Do not override the Cursor API key using plaintext environment variables."
    }
  }
}
