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
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "network_id" {
  type = string
}

variable "subnetwork_id" {
  type = string
}

variable "egress_policy_id" {
  type = string
}

variable "worker_image_repository" {
  type = string
}

variable "worker_image_digest" {
  type = string
}

variable "autoscaler_image_repository" {
  type = string
}

variable "autoscaler_image_digest" {
  type = string
}

variable "cursor_api_key_secret_id" {
  type = string
}

variable "cursor_api_key_secret_version" {
  type = string
}

variable "git_token_secret_id" {
  type    = string
  default = null
}

variable "git_token_secret_version" {
  type    = string
  default = null
}

variable "repo_url" {
  type = string
}

variable "repository_owner" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "development"
}

variable "notification_channel_ids" {
  type    = list(string)
  default = []
}

locals {
  repo_slug = "${var.repository_owner}/${var.repository_name}"
  labels = {
    example = "secure-default"
  }
}

module "project_bootstrap" {
  source = "../../modules/project-bootstrap"

  project_id = var.project_id
}

module "worker_identity" {
  source = "../../modules/runtime-identity"

  project_id  = var.project_id
  repository  = local.repo_slug
  environment = var.environment
}

module "autoscaler_identity" {
  source = "../../modules/runtime-identity"

  project_id          = var.project_id
  repository          = "${local.repo_slug}-scaler"
  environment         = var.environment
  account_id_override = substr("cur-scaler-${var.repository_name}-${var.environment}", 0, 30)
  description         = "Cursor autoscaler identity for ${local.repo_slug}"
}

module "secret_access_worker" {
  source = "../../modules/secret-bindings"

  project_id            = var.project_id
  service_account_email = module.worker_identity.email

  secrets = merge(
    {
      cursor = {
        secret_id = var.cursor_api_key_secret_id
      }
    },
    var.git_token_secret_id == null ? {} : {
      git = {
        secret_id = var.git_token_secret_id
      }
    }
  )
}

module "secret_access_autoscaler" {
  source = "../../modules/secret-bindings"

  project_id            = var.project_id
  service_account_email = module.autoscaler_identity.email

  secrets = {
    cursor = {
      secret_id = var.cursor_api_key_secret_id
    }
  }
}

module "network_profile" {
  source = "../../modules/network-profile"

  profile           = "restricted"
  network_id        = var.network_id
  subnetwork_id     = var.subnetwork_id
  route_all_traffic = true

  approved_egress_control = {
    resource_id = var.egress_policy_id
    owner       = "platform-networking"
  }
}

module "worker_pool" {
  source = "../../modules/cursor-worker-pool"

  project_id = var.project_id
  region     = var.region

  repository = {
    owner = var.repository_owner
    name  = var.repository_name
  }

  environment = var.environment

  image = {
    repository = var.worker_image_repository
    digest     = var.worker_image_digest
  }

  runtime_service_account_email = module.worker_identity.email

  # Autoscaler owns capacity after initial create.
  ignore_manual_instance_count_changes = true

  capacity = {
    instance_count = 1
    cpu            = "4"
    memory         = "8Gi"
  }

  plain_environment_variables = {
    REPO_URL                = var.repo_url
    CURSOR_WORKER_POOL_NAME = "${var.repository_name}-${var.environment}"
    PORT                    = "8080"
  }

  secret_environment_variables = merge(
    {
      CURSOR_API_KEY = {
        secret_id = var.cursor_api_key_secret_id
        version   = var.cursor_api_key_secret_version
      }
    },
    var.git_token_secret_id == null ? {} : {
      GIT_TOKEN = {
        secret_id = var.git_token_secret_id
        version   = var.git_token_secret_version
      }
    }
  )

  network = module.network_profile.worker_pool_network
  labels  = local.labels

  depends_on = [
    module.project_bootstrap,
    module.secret_access_worker,
  ]
}

# Grant autoscaler permission to update the worker pool instance count.
resource "google_cloud_run_v2_worker_pool_iam_member" "autoscaler_updater" {
  project  = var.project_id
  location = var.region
  name     = module.worker_pool.worker_pool_name
  role     = "roles/run.developer"
  member   = module.autoscaler_identity.member
}

module "autoscaler_pool" {
  source = "../../modules/cursor-worker-pool"

  project_id = var.project_id
  region     = var.region

  repository = {
    owner = var.repository_owner
    name  = "${var.repository_name}-autoscaler"
  }

  environment   = var.environment
  name_override = "cursor-${var.repository_name}-scaler-${var.environment}"

  image = {
    repository = var.autoscaler_image_repository
    digest     = var.autoscaler_image_digest
  }

  runtime_service_account_email = module.autoscaler_identity.email

  capacity = {
    instance_count = 1
    cpu            = "1"
    memory         = "512Mi"
  }

  plain_environment_variables = {
    GOOGLE_CLOUD_PROJECT = var.project_id
    CLOUD_RUN_LOCATION   = var.region
    WORKER_SERVICE_NAME  = module.worker_pool.worker_pool_name
    MIN_INSTANCES        = "1"
    MAX_INSTANCES        = "10"
    TARGET_UTILIZATION   = "0.5"
    POLLING_INTERVAL_MS  = "30000"
    PORT                 = "8080"
  }

  secret_environment_variables = {
    CURSOR_API_KEY = {
      secret_id = var.cursor_api_key_secret_id
      version   = var.cursor_api_key_secret_version
    }
  }

  network = module.network_profile.worker_pool_network

  security = {
    # Autoscaler does not use the Cursor management TCP probe the same way;
    # keep digest + identity requirements.
    require_network_attachment = true
  }

  labels = merge(local.labels, { component = "cursor-autoscaler" })

  depends_on = [
    module.secret_access_autoscaler,
    google_cloud_run_v2_worker_pool_iam_member.autoscaler_updater,
  ]
}

module "observability" {
  source = "../../modules/observability"

  project_id               = var.project_id
  region                   = var.region
  worker_pool_name         = module.worker_pool.worker_pool_name
  notification_channel_ids = var.notification_channel_ids
  labels                   = local.labels
}

output "worker_pool_name" {
  value = module.worker_pool.worker_pool_name
}

output "autoscaler_pool_name" {
  value = module.autoscaler_pool.worker_pool_name
}

output "worker_console_url" {
  value = module.worker_pool.console_url
}
