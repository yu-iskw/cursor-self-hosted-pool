variable "project_id" {
  type        = string
  description = "Project containing the Cloud Run Worker Pool."
}

variable "region" {
  type        = string
  description = "Google Cloud region."
}

variable "repository" {
  type = object({
    owner = string
    name  = string
  })
  description = "Source repository owner and name used for naming and labels."
}

variable "environment" {
  type        = string
  description = "Deployment environment, for example development, staging, or production."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.environment))
    error_message = "environment must be lowercase alphanumeric with hyphens, max 31 characters."
  }
}

variable "name_prefix" {
  type        = string
  description = "Optional organizational prefix for the worker pool name."
  default     = "cursor"
}

variable "name_override" {
  type        = string
  description = "Optional explicit worker pool name. When null, a deterministic name is generated. Must be 49 characters or fewer (Cloud Run Worker Pool limit)."
  default     = null

  validation {
    condition     = var.name_override == null ? true : length(var.name_override) <= 49
    error_message = "name_override must be 49 characters or fewer (Cloud Run Worker Pool name limit)."
  }
}

variable "image" {
  type = object({
    repository = string
    digest     = string
  })
  description = "Immutable container image (repository + sha256 digest)."

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.image.digest))
    error_message = "image.digest must be a SHA-256 digest (sha256: followed by 64 hex characters)."
  }

  validation {
    condition     = !can(regex(":(latest|main|master)$", var.image.repository))
    error_message = "image.repository must not end with a mutable tag such as :latest."
  }
}

variable "runtime_service_account_email" {
  type        = string
  description = "Dedicated user-managed service account attached to the pool."

  validation {
    condition     = length(var.runtime_service_account_email) > 0
    error_message = "runtime_service_account_email must not be empty."
  }
}

variable "capacity" {
  type = object({
    instance_count = number
    cpu            = string
    memory         = string
  })
  description = "Manual instance count and container resources."

  validation {
    condition     = var.capacity.instance_count >= 0 && var.capacity.instance_count <= 50
    error_message = "capacity.instance_count must be between 0 and 50."
  }
}

variable "capacity_policy" {
  type = object({
    minimum_cpu            = optional(number, 1)
    maximum_cpu            = optional(number, 8)
    minimum_memory_gib     = optional(number, 1)
    maximum_memory_gib     = optional(number, 32)
    maximum_instance_count = optional(number, 50)
  })
  description = "Platform-defined capacity bounds."
  default     = {}
}

variable "plain_environment_variables" {
  type        = map(string)
  default     = {}
  description = "Non-secret environment variables only."
}

variable "secret_environment_variables" {
  type = map(object({
    secret_id = string
    version   = string
  }))
  default     = {}
  description = "Secret Manager references exposed as environment variables. Pin versions unless an exception is granted."
}

variable "secret_mounts" {
  type = map(object({
    secret_id  = string
    version    = string
    mount_path = string
    file_name  = string
  }))
  default     = {}
  description = "Secret Manager references mounted as files."
}

variable "command" {
  type        = list(string)
  default     = null
  description = "Optional container command override."
}

variable "args" {
  type        = list(string)
  default     = null
  description = "Optional container args."
}

variable "network" {
  type = object({
    profile           = string
    network_id        = optional(string)
    subnetwork_id     = optional(string)
    route_all_traffic = optional(bool, true)
    connector_id      = optional(string)
    tags              = optional(list(string), [])
    approved_egress_control = optional(object({
      resource_id = string
      owner       = string
    }))
  })
  description = "Network profile and VPC attachment settings."

  validation {
    condition = contains(
      ["unrestricted", "nat-logged", "restricted", "private-only", "custom"],
      var.network.profile
    )
    error_message = "network.profile must be one of: unrestricted, nat-logged, restricted, private-only, custom."
  }
}

variable "security" {
  type = object({
    prohibit_default_identity       = optional(bool, true)
    require_network_attachment      = optional(bool, true)
    deletion_protection             = optional(bool, true)
    require_pinned_secret_versions  = optional(bool, true)
    allowed_image_registry_prefixes = optional(list(string), [])
  })
  description = "Secure-by-default toggles. Image digests are always required via var.image validation."
  default     = {}
}

variable "exceptions" {
  type = map(object({
    ticket     = string
    expires_on = string
    reason     = string
  }))
  default     = {}
  description = "Explicit, time-bounded policy exceptions. Keys are exception names."

  validation {
    condition = alltrue([
      for k, v in var.exceptions :
      can(regex("^[A-Z]+-[0-9]+$", v.ticket)) && can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", v.expires_on))
    ])
    error_message = "Each exception requires ticket like SEC-1234 and expires_on as YYYY-MM-DD."
  }
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels merged with required module labels."
}

variable "team" {
  type        = string
  default     = "unset"
  description = "Operational owning team (label)."
}

variable "cost_center" {
  type        = string
  default     = "unset"
  description = "Cost center (label)."
}

variable "data_classification" {
  type        = string
  default     = "internal"
  description = "Data classification label."
}

variable "module_version_label" {
  type        = string
  default     = "0.1.0"
  description = "Module version embedded in labels for inventory."
}

variable "description" {
  type        = string
  default     = null
  description = "Optional worker pool description."
}

variable "ignore_manual_instance_count_changes" {
  type        = bool
  default     = false
  description = "When true, Terraform ignores changes to scaling.manual_instance_count (use when an autoscaler owns capacity). WARNING: toggling this after create replaces the Worker Pool resource address (this <-> autoscaled). Set at create time and keep stable."
}

variable "binary_authorization" {
  type = object({
    use_default              = optional(bool)
    breakglass_justification = optional(string)
    policy                   = optional(string)
  })
  default     = null
  description = "Optional Binary Authorization settings."
}

variable "startup_probe_port" {
  type        = number
  default     = 8080
  description = "TCP startup probe port (Cursor management server / Cloud Run PORT)."
}
