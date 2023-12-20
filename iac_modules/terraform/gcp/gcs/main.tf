resource "google_storage_bucket" "terraform_state_bucket" {
  name          = local.config.bucket_name
  location      = local.config.region
  force_destroy = true
}
