terraform {
  required_version = ">= 1.6.0"
}

variable "profile" {
  type        = string
  description = "Network profile name."

  validation {
    condition = contains(
      ["unrestricted", "nat-logged", "restricted", "private-only", "custom"],
      var.profile
    )
    error_message = "profile must be one of: unrestricted, nat-logged, restricted, private-only, custom."
  }
}

variable "network_id" {
  type        = string
  default     = null
  description = "VPC network ID or self-link."
}

variable "subnetwork_id" {
  type        = string
  default     = null
  description = "Subnet ID or self-link."
}

variable "connector_id" {
  type        = string
  default     = null
  description = "Optional Serverless VPC Access connector."
}

variable "route_all_traffic" {
  type        = bool
  default     = true
  description = "When true, egress is ALL_TRAFFIC (required for restricted)."
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Network tags applied to the worker pool."
}

variable "approved_egress_control" {
  type = object({
    resource_id = string
    owner       = string
  })
  default     = null
  description = "Attestation that an approved egress control exists (does not prove enforcement)."
}

variable "custom_settings" {
  type        = any
  default     = null
  description = "Caller-supplied settings when profile=custom (passed through)."
}

locals {
  restricted_requires = var.profile != "restricted" || (
    var.network_id != null &&
    var.subnetwork_id != null &&
    var.route_all_traffic &&
    var.approved_egress_control != null
  )
}

check "restricted_inputs" {
  assert {
    condition     = local.restricted_requires
    error_message = "restricted profile requires network_id, subnetwork_id, route_all_traffic=true, and approved_egress_control."
  }
}

output "worker_pool_network" {
  description = "Object suitable for modules/cursor-worker-pool network input."
  value = var.profile == "custom" && var.custom_settings != null ? var.custom_settings : {
    profile                 = var.profile
    network_id              = var.network_id
    subnetwork_id           = var.subnetwork_id
    connector_id            = var.connector_id
    route_all_traffic       = var.route_all_traffic
    tags                    = var.tags
    approved_egress_control = var.approved_egress_control
  }
}

output "profile" {
  value       = var.profile
  description = "Selected network profile."
}
