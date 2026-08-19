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
  description = "Cloudflare zone ID containing the serverless Billing custom domain"
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID owning the core Edge Gateway Worker"
}

variable "billing_host" {
  type        = string
  description = "Public Billing Worker custom domain"
  default     = "billing-serverless-uat.onwalk.net"
}

variable "edge_gateway_core_worker" {
  type        = string
  description = "Core Edge Gateway Worker service that proxies Billing to Cloud Run"
  default     = "edge-gateway-core-uat"
}
