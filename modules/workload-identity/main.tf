terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.38.0, < 8.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.38.0, < 8.0.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "GCP project for the workload identity pool."
}

variable "pool_id" {
  type        = string
  description = "Workload identity pool ID."
  default     = "cursor-ci"
}

variable "pool_display_name" {
  type        = string
  default     = "Cursor CI"
  description = "Display name for the pool."
}

variable "provider_id" {
  type        = string
  default     = "github"
  description = "Provider ID within the pool."
}

variable "issuer_uri" {
  type        = string
  default     = "https://token.actions.githubusercontent.com"
  description = "OIDC issuer URI (GitHub Actions by default)."
}

variable "attribute_condition" {
  type        = string
  description = "CEL attribute condition restricting which identities can federate."
}

variable "attribute_mapping" {
  type        = map(string)
  description = "OIDC attribute mapping."
  default = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
}

resource "google_iam_workload_identity_pool" "this" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_display_name
  description               = "Workload Identity Federation for Cursor pool CI deployers"
}

resource "google_iam_workload_identity_pool_provider" "this" {
  provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_id
  attribute_mapping                  = var.attribute_mapping
  attribute_condition                = var.attribute_condition

  oidc {
    issuer_uri = var.issuer_uri
  }
}

output "pool_name" {
  description = "Workload identity pool resource name."
  value       = google_iam_workload_identity_pool.this.name
}

output "provider_name" {
  description = "Workload identity provider resource name."
  value       = google_iam_workload_identity_pool_provider.this.name
}
