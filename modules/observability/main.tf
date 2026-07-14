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
  description = "Project for monitoring resources."
}

variable "worker_pool_name" {
  type        = string
  description = "Worker pool name to monitor."
}

variable "region" {
  type        = string
  description = "Worker pool region."
}

variable "notification_channel_ids" {
  type        = list(string)
  default     = []
  description = "Existing notification channel IDs. This module does not create org-wide channels."
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for alert policies."
}

variable "enable_zero_instance_alert" {
  type        = bool
  default     = true
  description = "Alert when instance count is zero for a sustained period."
}

variable "zero_instance_duration" {
  type        = string
  default     = "900s"
  description = "Duration before zero-instance alert fires."
}

resource "google_monitoring_alert_policy" "zero_instances" {
  count = var.enable_zero_instance_alert ? 1 : 0

  project      = var.project_id
  display_name = "Cursor pool zero instances: ${var.worker_pool_name}"
  combiner     = "OR"
  user_labels  = var.labels

  conditions {
    display_name = "Worker pool instance count is zero"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloud_run_revision"
        AND resource.labels.service_name = "${var.worker_pool_name}"
        AND metric.type = "run.googleapis.com/container/instance_count"
      EOT

      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = var.zero_instance_duration

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channel_ids

  documentation {
    content   = "Cursor worker pool ${var.worker_pool_name} in ${var.region} has zero instances. See docs/runbooks/disable-pool.md and docs/runbooks/failed-revision.md."
    mime_type = "text/markdown"
  }
}

output "alert_policy_ids" {
  description = "Created alert policy IDs."
  value = compact([
    try(google_monitoring_alert_policy.zero_instances[0].id, null),
  ])
}
