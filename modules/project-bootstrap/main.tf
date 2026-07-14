terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.38.0, < 8.0.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Project in which to enable APIs."
}

variable "activate_apis" {
  type = list(string)
  default = [
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
  description = "APIs to enable. Optional — many enterprises centralize API enablement."
}

variable "disable_on_destroy" {
  type        = bool
  default     = false
  description = "Whether to disable APIs on destroy."
}

resource "google_project_service" "apis" {
  for_each = toset(var.activate_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = var.disable_on_destroy
}

output "enabled_apis" {
  description = "APIs requested by this module."
  value       = sort(var.activate_apis)
}
