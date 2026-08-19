output "accounts_service_uri" {
  description = "URI of the accounts Cloud Run UAT service"
  value       = google_cloud_run_v2_service.accounts_uat.uri
}

output "billing_service_uri" {
  description = "URI of the billing Cloud Run UAT service"
  value       = google_cloud_run_v2_service.billing_uat.uri
}

output "content_service_uri" {
  description = "URI of the content Cloud Run UAT service"
  value       = google_cloud_run_v2_service.content_uat.uri
}

output "billing_host" {
  description = "Billing custom domain owned by the core Edge Gateway Worker"
  value       = cloudflare_workers_domain.billing.hostname
}

output "billing_worker_service" {
  description = "Worker service attached to the Billing custom domain"
  value       = cloudflare_workers_domain.billing.service
}
