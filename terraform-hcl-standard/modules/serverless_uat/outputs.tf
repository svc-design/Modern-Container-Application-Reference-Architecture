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

output "billing_origin_host" {
  description = "DNS-only Cloudflare hostname used for the Billing origin override"
  value       = cloudflare_record.billing_origin.name
}

output "billing_origin_target" {
  description = "Cloud Run hostname targeted by the Billing origin alias"
  value       = cloudflare_record.billing_origin.content
}
