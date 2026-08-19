variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID for UAT Serverless Stack"
  default     = "ai-workspace-uat-project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region for Cloud Run"
  default     = "asia-east1"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag for microservices"
  default     = "latest"
}

variable "supabase_pooler_url" {
  type        = string
  description = "Supabase Supavisor Pooler URL (Port 6543)"
  sensitive   = true
  default     = ""
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID containing the serverless Billing origin alias"
}

variable "billing_origin_host" {
  type        = string
  description = "DNS-only same-zone hostname used by the Cloudflare Billing Origin Rule"
  default     = "billing-origin-serverless-uat.onwalk.net"
}
