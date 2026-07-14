terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.38.0, < 8.0.0"
    }
  }
}

variable "project_id" { type = string }
variable "region" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "egress_policy_id" { type = string }
variable "worker_image_repository" { type = string }
variable "worker_image_digest" { type = string }
variable "repository_owner" { type = string }
variable "repository_name" { type = string }
variable "repo_url" { type = string }

variable "environments" {
  type = map(object({
    cursor_api_key_secret_id      = string
    cursor_api_key_secret_version = string
  }))
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

module "runtime_identity" {
  for_each    = var.environments
  source      = "../../modules/runtime-identity"
  project_id  = var.project_id
  repository  = "${var.repository_owner}/${var.repository_name}"
  environment = each.key
}

module "cursor_pool" {
  for_each                      = var.environments
  source                        = "../../modules/cursor-worker-pool"
  project_id                    = var.project_id
  region                        = var.region
  repository                    = { owner = var.repository_owner, name = var.repository_name }
  environment                   = each.key
  image                         = { repository = var.worker_image_repository, digest = var.worker_image_digest }
  runtime_service_account_email = module.runtime_identity[each.key].email
  capacity                      = { instance_count = 1, cpu = "4", memory = "8Gi" }
  plain_environment_variables   = { REPO_URL = var.repo_url, PORT = "8080" }
  secret_environment_variables = {
    CURSOR_API_KEY = {
      secret_id = each.value.cursor_api_key_secret_id
      version   = each.value.cursor_api_key_secret_version
    }
  }
  network = module.network_profile.worker_pool_network
}

output "pools" {
  value = { for k, m in module.cursor_pool : k => m.worker_pool_name }
}
