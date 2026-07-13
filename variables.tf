variable "project_id" {
  description = "Google Cloud project ID that hosts the worker pool."
  type        = string
}

variable "region" {
  description = "Google Cloud region."
  type        = string
}

variable "name" {
  description = "Cloud Run worker pool name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,47}[a-z0-9]$", var.name))
    error_message = "name must be a lowercase Cloud Run-compatible name between 2 and 49 characters."
  }
}

variable "container_image" {
  description = "Immutable Cursor worker container image reference. Pin by digest in production."
  type        = string

  validation {
    condition     = !var.require_image_digest || can(regex("@sha256:[0-9a-f]{64}$", var.container_image))
    error_message = "container_image must be pinned by sha256 digest when require_image_digest is true."
  }
}

variable "require_image_digest" {
  description = "Require an immutable sha256 image digest."
  type        = bool
  default     = true
}

variable "cursor_api_key_secret_id" {
  description = "Secret Manager secret ID containing the Cursor API key. The module never accepts the secret value."
  type        = string
}

variable "cursor_api_key_secret_version" {
  description = "Secret version exposed to the worker. Pin a numeric version for deterministic rollouts."
  type        = string
  default     = "latest"
}

variable "service_account_email" {
  description = "Existing least-privilege runtime service account. If null, the module creates one."
  type        = string
  default     = null
}

variable "create_service_account" {
  description = "Create a dedicated runtime service account."
  type        = bool
  default     = true
}

variable "service_account_id" {
  description = "Account ID used when creating the runtime service account."
  type        = string
  default     = null
}

variable "worker_count" {
  description = "Fixed number of worker instances."
  type        = number
  default     = 1

  validation {
    condition     = var.worker_count >= 0 && floor(var.worker_count) == var.worker_count
    error_message = "worker_count must be a non-negative integer."
  }
}

variable "cpu" {
  description = "CPU limit per worker container."
  type        = string
  default     = "2"
}

variable "memory" {
  description = "Memory limit per worker container."
  type        = string
  default     = "4Gi"
}

variable "command" {
  description = "Optional container entrypoint override."
  type        = list(string)
  default     = null
}

variable "args" {
  description = "Optional container arguments."
  type        = list(string)
  default     = null
}

variable "environment" {
  description = "Non-secret environment variables. Sensitive values must use Secret Manager."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "cursor_api_key_environment_name" {
  description = "Environment variable expected by the Cursor worker image."
  type        = string
  default     = "CURSOR_API_KEY"
}

variable "vpc_access" {
  description = "Optional Direct VPC egress configuration."
  type = object({
    network_interfaces = list(object({
      network    = string
      subnetwork = string
      tags       = optional(list(string), [])
    }))
    egress = optional(string, "PRIVATE_RANGES_ONLY")
  })
  default = null
}

variable "execution_environment" {
  description = "Cloud Run execution environment."
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Protect the worker pool from accidental Terraform deletion."
  type        = bool
  default     = true
}

variable "manage_project_services" {
  description = "Enable required Google Cloud APIs. Disable when APIs are centrally managed."
  type        = bool
  default     = false
}
