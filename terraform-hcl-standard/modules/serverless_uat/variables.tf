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
