terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.38.0, < 8.0.0"
    }
  }
}

# Multiple repository pools in one central execution project.
# Each pool still gets a dedicated runtime identity.

variable "project_id" { type = string }
variable "region" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "egress_policy_id" { type = string }
variable "worker_image_repository" { type = string }
variable "worker_image_digest" { type = string }

variable "pools" {
  type = map(object({
    repository_owner              = string
    repository_name               = string
    environment                   = string
    repo_url                      = string
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
  for_each    = var.pools
  source      = "../../modules/runtime-identity"
  project_id  = var.project_id
  repository  = "${each.value.repository_owner}/${each.value.repository_name}"
  environment = each.value.environment
}

module "secrets" {
  for_each              = var.pools
  source                = "../../modules/secret-bindings"
  project_id            = var.project_id
  service_account_email = module.runtime_identity[each.key].email
  secrets               = { cursor = { secret_id = each.value.cursor_api_key_secret_id } }
}

module "cursor_pool" {
  for_each                      = var.pools
  source                        = "../../modules/cursor-worker-pool"
  project_id                    = var.project_id
  region                        = var.region
  repository                    = { owner = each.value.repository_owner, name = each.value.repository_name }
  environment                   = each.value.environment
  image                         = { repository = var.worker_image_repository, digest = var.worker_image_digest }
  runtime_service_account_email = module.runtime_identity[each.key].email
  capacity                      = { instance_count = 1, cpu = "4", memory = "8Gi" }
  plain_environment_variables   = { REPO_URL = each.value.repo_url, PORT = "8080" }
  secret_environment_variables = {
    CURSOR_API_KEY = {
      secret_id = each.value.cursor_api_key_secret_id
      version   = each.value.cursor_api_key_secret_version
    }
  }
  network    = module.network_profile.worker_pool_network
  depends_on = [module.secrets]
}

output "worker_pool_names" {
  value = { for k, m in module.cursor_pool : k => m.worker_pool_name }
}
