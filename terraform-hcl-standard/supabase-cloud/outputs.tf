output "project_ref" {
  description = "Supabase project reference."
  value       = local.effective_project_ref
}

output "pooler_uris" {
  description = "Supavisor connection URIs keyed by session and transaction mode."
  value       = data.supabase_pooler.this.url
  sensitive   = true
}

output "database_uri" {
  description = "Selected database URI: explicit database_uri, otherwise the selected Supavisor mode."
  value       = local.configured_database_uri
  sensitive   = true
}

output "connection" {
  description = "Database connection contract for downstream deployment consumers."
  value = {
    username = var.database_username
    database = var.database_name
    uri      = local.configured_database_uri
    mode     = local.has_explicit_database_uri ? "explicit" : var.pooler_mode
  }
  sensitive = true
}
