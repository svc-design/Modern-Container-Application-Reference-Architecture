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
