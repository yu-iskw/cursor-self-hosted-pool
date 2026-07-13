terraform {
  required_version = ">= 1.8.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "cursor_pool" {
  source = "../.."

  project_id   = var.project_id
  region       = var.region
  name         = "cursor-agents"
  container_image = var.container_image

  cursor_api_key_secret_id      = var.cursor_api_key_secret_id
  cursor_api_key_secret_version = var.cursor_api_key_secret_version

  worker_count         = 2
  cpu                  = "2"
  memory               = "4Gi"
  deletion_protection  = true
  manage_project_services = false

  environment = {
    LOG_LEVEL = "info"
  }

  labels = {
    environment = "production"
    owner       = "platform-engineering"
  }
}
