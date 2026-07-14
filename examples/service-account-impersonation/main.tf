terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.38.0, < 8.0.0"
    }
  }
}

# Keep the pool runtime SA minimal; grant tokenCreator on a narrow target SA.

variable "project_id" { type = string }
variable "region" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "egress_policy_id" { type = string }
variable "worker_image_repository" { type = string }
variable "worker_image_digest" { type = string }
variable "cursor_api_key_secret_id" { type = string }
variable "cursor_api_key_secret_version" { type = string }
variable "repo_url" { type = string }
variable "repository_owner" { type = string }
variable "repository_name" { type = string }
variable "environment" { type = string }
variable "target_service_account_email" { type = string }

module "runtime_identity" {
  source      = "../../modules/runtime-identity"
  project_id  = var.project_id
  repository  = "${var.repository_owner}/${var.repository_name}"
  environment = var.environment
}

resource "google_service_account_iam_member" "impersonate_target" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.target_service_account_email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = module.runtime_identity.member
}

module "network_profile" {
  source            = "../../modules/network-profile"
  profile           = "restricted"
  network_id        = var.network_id
  subnetwork_id     = var.subnetwork_id
  route_all_traffic = true
  approved_egress_control = {
    resource_id = var.egress_policy_id
    owner       = "platform-networking"
  }
}

module "cursor_pool" {
  source                        = "../../modules/cursor-worker-pool"
  project_id                    = var.project_id
  region                        = var.region
  repository                    = { owner = var.repository_owner, name = var.repository_name }
  environment                   = var.environment
  image                         = { repository = var.worker_image_repository, digest = var.worker_image_digest }
  runtime_service_account_email = module.runtime_identity.email
  capacity                      = { instance_count = 1, cpu = "4", memory = "8Gi" }
  plain_environment_variables = {
    REPO_URL               = var.repo_url
    PORT                   = "8080"
    TARGET_SERVICE_ACCOUNT = var.target_service_account_email
  }
  secret_environment_variables = {
    CURSOR_API_KEY = { secret_id = var.cursor_api_key_secret_id, version = var.cursor_api_key_secret_version }
  }
  network = module.network_profile.worker_pool_network
}

output "runtime_service_account_email" { value = module.runtime_identity.email }
output "worker_pool_name" { value = module.cursor_pool.worker_pool_name }
