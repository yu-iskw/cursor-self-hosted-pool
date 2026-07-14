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
  description = "Project used when secret_id is not a full resource name."
  default     = null
}

variable "service_account_email" {
  type        = string
  description = "Runtime service account that receives secretAccessor."
}

variable "secrets" {
  type = map(object({
    secret_id = string
  }))
  description = "Map of logical names to Secret Manager secret IDs (ID or full resource name)."
}

variable "create_secret_placeholders" {
  type        = bool
  default     = false
  description = "When true, create empty secret containers for secrets that use short IDs. Never populates secret payloads."
}

locals {
  member = "serviceAccount:${var.service_account_email}"

  secrets = {
    for k, v in var.secrets : k => {
      secret_id = v.secret_id
      # google_secret_manager_secret_iam_member accepts secret_id or full name
      is_full = startswith(v.secret_id, "projects/")
    }
  }
}

resource "google_secret_manager_secret" "placeholder" {
  for_each = var.create_secret_placeholders ? {
    for k, v in local.secrets : k => v if !v.is_full
  } : {}

  project   = var.project_id
  secret_id = each.value.secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = local.secrets

  project = var.project_id
  secret_id = each.value.is_full ? each.value.secret_id : (
    var.create_secret_placeholders ? google_secret_manager_secret.placeholder[each.key].secret_id : each.value.secret_id
  )
  role   = "roles/secretmanager.secretAccessor"
  member = local.member
}

output "secret_ids" {
  description = "Secret IDs that were bound."
  value       = { for k, v in local.secrets : k => v.secret_id }
}

output "members" {
  description = "IAM members granted accessor."
  value       = [local.member]
}
