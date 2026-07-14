locals {
  pool = try(google_cloud_run_v2_worker_pool.this[0], google_cloud_run_v2_worker_pool.autoscaled[0])
}

output "worker_pool_name" {
  description = "Name of the Cloud Run Worker Pool."
  value       = local.pool.name
}

output "worker_pool_id" {
  description = "Fully qualified Worker Pool ID."
  value       = local.pool.id
}

output "worker_pool_location" {
  description = "Region of the Worker Pool."
  value       = local.pool.location
}

output "latest_ready_revision" {
  description = "Latest ready revision name when reported by the API."
  value       = try(local.pool.latest_ready_revision, null)
}

output "runtime_service_account_email" {
  description = "Runtime service account attached to the pool."
  value       = var.runtime_service_account_email
}

output "image_reference" {
  description = "Deployed image reference (repository@digest)."
  value       = local.image_reference
}

output "labels" {
  description = "Effective labels applied by the module."
  value       = local.labels
}

output "console_url" {
  description = "Google Cloud Console URL for the Worker Pool."
  value       = "https://console.cloud.google.com/run/workerPools/details/${var.region}/${local.pool.name}?project=${var.project_id}"
}
