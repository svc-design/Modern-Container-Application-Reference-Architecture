locals {
  effective_project_ref = coalesce(var.project_ref, supabase_project.this.id)
  has_explicit_database_uri = try(trimspace(var.database_uri), "") != ""
  configured_database_uri = (
    local.has_explicit_database_uri
    ? var.database_uri
    : lookup(data.supabase_pooler.this.url, var.pooler_mode, "")
  )
}

# Supabase projects are importable and can also be created by this resource.
# database_password is intentionally ignored after the first apply: Supabase
# owns the live password and the secret must not be rotated by an accidental
# tfvars change.
resource "supabase_project" "this" {
  organization_id   = var.organization_id
  name              = var.project_name
  database_password = var.database_password
  region            = var.region
  instance_size     = var.instance_size

  lifecycle {
    ignore_changes = [database_password]
  }
}

# The provider exposes the official Supavisor connection strings. The data
# source returns session and transaction URLs; the chosen one is surfaced via
# a sensitive output for Vault/deployment consumers.
data "supabase_pooler" "this" {
  project_ref = local.effective_project_ref
}
