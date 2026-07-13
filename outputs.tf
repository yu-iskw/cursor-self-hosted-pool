output "worker_pool_name" {
  description = "Cloud Run worker pool name."
  value       = google_cloud_run_v2_worker_pool.this.name
}

output "worker_pool_id" {
  description = "Fully qualified Cloud Run worker pool ID."
  value       = google_cloud_run_v2_worker_pool.this.id
}

output "service_account_email" {
  description = "Runtime service account email."
  value       = local.service_account_email
}
