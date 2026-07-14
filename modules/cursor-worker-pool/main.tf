# Two resources exist solely because Terraform lifecycle.ignore_changes must be
# a static list (cannot be conditional). Keep templates identical when editing.
# WARNING: toggling ignore_manual_instance_count_changes replaces the pool
# (this <-> autoscaled address change). Set the flag at create time and keep it.
resource "google_cloud_run_v2_worker_pool" "this" {
  count = var.ignore_manual_instance_count_changes ? 0 : 1

  name                = local.worker_pool_name
  location            = var.region
  project             = var.project_id
  description         = var.description
  labels              = local.labels
  deletion_protection = local.deletion_protection

  scaling {
    scaling_mode          = "MANUAL"
    manual_instance_count = var.capacity.instance_count
  }

  dynamic "binary_authorization" {
    for_each = var.binary_authorization == null ? [] : [var.binary_authorization]
    content {
      use_default              = binary_authorization.value.use_default
      breakglass_justification = binary_authorization.value.breakglass_justification
      policy                   = binary_authorization.value.policy
    }
  }

  template {
    service_account = var.runtime_service_account_email
    labels          = local.labels

    dynamic "vpc_access" {
      for_each = local.vpc_configured ? [1] : []
      content {
        connector = try(var.network.connector_id, null)
        egress    = local.egress

        dynamic "network_interfaces" {
          for_each = try(var.network.connector_id, null) == null && try(var.network.network_id, null) != null ? [1] : []
          content {
            network    = var.network.network_id
            subnetwork = var.network.subnetwork_id
            tags       = var.network.tags
          }
        }
      }
    }

    containers {
      image   = local.image_reference
      command = var.command
      args    = var.args

      resources {
        limits = {
          cpu    = var.capacity.cpu
          memory = var.capacity.memory
        }
      }

      dynamic "env" {
        for_each = var.plain_environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.version
            }
          }
        }
      }

      dynamic "volume_mounts" {
        for_each = var.secret_mounts
        content {
          name       = volume_mounts.key
          mount_path = volume_mounts.value.mount_path
        }
      }

      startup_probe {
        tcp_socket {
          port = var.startup_probe_port
        }
        failure_threshold = 5
        period_seconds    = 10
        timeout_seconds   = 3
      }
    }

    dynamic "volumes" {
      for_each = var.secret_mounts
      content {
        name = volumes.key
        secret {
          secret = volumes.value.secret_id
          items {
            path    = volumes.value.file_name
            version = volumes.value.version
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !var.security.prohibit_default_identity || !local.runtime_is_default_compute_sa
      error_message = "A default Compute Engine service account cannot be used as the runtime identity."
    }
    precondition {
      condition = (
        !var.security.require_network_attachment ||
        var.network.profile == "unrestricted" ||
        local.allow_unrestricted_egress ||
        local.vpc_configured
      )
      error_message = "A VPC network attachment (Direct VPC or connector) is required for this network profile."
    }
    precondition {
      condition     = local.restricted_ok || local.allow_unrestricted_egress
      error_message = "The restricted network profile requires network, subnet, route_all_traffic=true, and approved_egress_control."
    }
    precondition {
      condition     = local.secret_versions_ok
      error_message = "Secret versions must be pinned (not \"latest\") unless exception allow_secret_version_latest is set."
    }
    precondition {
      condition     = local.registry_ok
      error_message = "image.repository is not under security.allowed_image_registry_prefixes."
    }
    precondition {
      condition     = length(local.expired_exceptions) == 0
      error_message = "One or more policy exceptions have expired."
    }
    precondition {
      condition     = var.network.profile != "unrestricted" || local.allow_unrestricted_egress
      error_message = "network.profile=unrestricted requires exceptions.allow_unrestricted_egress."
    }
  }
}

resource "google_cloud_run_v2_worker_pool" "autoscaled" {
  count = var.ignore_manual_instance_count_changes ? 1 : 0

  name                = local.worker_pool_name
  location            = var.region
  project             = var.project_id
  description         = var.description
  labels              = local.labels
  deletion_protection = local.deletion_protection

  scaling {
    scaling_mode          = "MANUAL"
    manual_instance_count = var.capacity.instance_count
  }

  dynamic "binary_authorization" {
    for_each = var.binary_authorization == null ? [] : [var.binary_authorization]
    content {
      use_default              = binary_authorization.value.use_default
      breakglass_justification = binary_authorization.value.breakglass_justification
      policy                   = binary_authorization.value.policy
    }
  }

  template {
    service_account = var.runtime_service_account_email
    labels          = local.labels

    dynamic "vpc_access" {
      for_each = local.vpc_configured ? [1] : []
      content {
        connector = try(var.network.connector_id, null)
        egress    = local.egress

        dynamic "network_interfaces" {
          for_each = try(var.network.connector_id, null) == null && try(var.network.network_id, null) != null ? [1] : []
          content {
            network    = var.network.network_id
            subnetwork = var.network.subnetwork_id
            tags       = var.network.tags
          }
        }
      }
    }

    containers {
      image   = local.image_reference
      command = var.command
      args    = var.args

      resources {
        limits = {
          cpu    = var.capacity.cpu
          memory = var.capacity.memory
        }
      }

      dynamic "env" {
        for_each = var.plain_environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.version
            }
          }
        }
      }

      dynamic "volume_mounts" {
        for_each = var.secret_mounts
        content {
          name       = volume_mounts.key
          mount_path = volume_mounts.value.mount_path
        }
      }

      startup_probe {
        tcp_socket {
          port = var.startup_probe_port
        }
        failure_threshold = 5
        period_seconds    = 10
        timeout_seconds   = 3
      }
    }

    dynamic "volumes" {
      for_each = var.secret_mounts
      content {
        name = volumes.key
        secret {
          secret = volumes.value.secret_id
          items {
            path    = volumes.value.file_name
            version = volumes.value.version
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      scaling[0].manual_instance_count,
    ]

    precondition {
      condition     = !var.security.prohibit_default_identity || !local.runtime_is_default_compute_sa
      error_message = "A default Compute Engine service account cannot be used as the runtime identity."
    }
    precondition {
      condition = (
        !var.security.require_network_attachment ||
        var.network.profile == "unrestricted" ||
        local.allow_unrestricted_egress ||
        local.vpc_configured
      )
      error_message = "A VPC network attachment (Direct VPC or connector) is required for this network profile."
    }
    precondition {
      condition     = local.restricted_ok || local.allow_unrestricted_egress
      error_message = "The restricted network profile requires network, subnet, route_all_traffic=true, and approved_egress_control."
    }
    precondition {
      condition     = local.secret_versions_ok
      error_message = "Secret versions must be pinned (not \"latest\") unless exception allow_secret_version_latest is set."
    }
    precondition {
      condition     = local.registry_ok
      error_message = "image.repository is not under security.allowed_image_registry_prefixes."
    }
    precondition {
      condition     = length(local.expired_exceptions) == 0
      error_message = "One or more policy exceptions have expired."
    }
    precondition {
      condition     = var.network.profile != "unrestricted" || local.allow_unrestricted_egress
      error_message = "network.profile=unrestricted requires exceptions.allow_unrestricted_egress."
    }
  }
}
