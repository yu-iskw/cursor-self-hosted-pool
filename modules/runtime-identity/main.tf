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
  description = "Project that owns the runtime service account."
}

variable "repository" {
  type        = string
  description = "Repository slug, for example example-org/example-service."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "account_id_override" {
  type        = string
  default     = null
  description = "Optional explicit service account ID (6-30 chars)."
}

variable "display_name" {
  type        = string
  default     = null
  description = "Optional display name."
}

variable "description" {
  type        = string
  default     = "Cursor self-hosted pool runtime identity"
  description = "Service account description."
}

locals {
  normalized_repo = lower(replace(replace(var.repository, "/", "-"), "/[^a-z0-9-]/", "-"))
  account_id = coalesce(
    var.account_id_override,
    substr("cur-${local.normalized_repo}-${var.environment}", 0, 30)
  )
}

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = local.account_id
  display_name = coalesce(var.display_name, "Cursor pool ${var.repository} ${var.environment}")
  description  = var.description
}

output "email" {
  description = "Service account email."
  value       = google_service_account.runtime.email
}

output "id" {
  description = "Service account unique ID."
  value       = google_service_account.runtime.unique_id
}

output "member" {
  description = "IAM member string."
  value       = google_service_account.runtime.member
}

output "name" {
  description = "Fully qualified service account name."
  value       = google_service_account.runtime.name
}

output "account_id" {
  description = "Service account ID."
  value       = google_service_account.runtime.account_id
}
