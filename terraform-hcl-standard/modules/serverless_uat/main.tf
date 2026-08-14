# -----------------------------------------------------------------------------
# UAT on Serverless Terraform Module
# 包含 GCP Cloud Run v2 (min=0) 与 Cloudflare Worker / Pages 基础设施声明
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0.0"
    }
  }
}

# 1. GCP Cloud Run v2 声明: accounts 微服务
resource "google_cloud_run_v2_service" "accounts_uat" {
  name     = "uat-accounts"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
    containers {
      image = "asia-east1-docker.pkg.dev/${var.gcp_project_id}/serverless/accounts:${var.image_tag}"
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
      env {
        name  = "ENV"
        value = "uat"
      }
      env {
        name  = "DATABASE_URL"
        value = var.supabase_pooler_url
      }
    }
  }
}

# 2. GCP Cloud Run v2 声明: billing-service 微服务
resource "google_cloud_run_v2_service" "billing_uat" {
  name     = "uat-billing-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
    containers {
      image = "asia-east1-docker.pkg.dev/${var.gcp_project_id}/serverless/billing-service:${var.image_tag}"
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
      env {
        name  = "ENV"
        value = "uat"
      }
      env {
        name  = "DATABASE_URL"
        value = var.supabase_pooler_url
      }
    }
  }
}

# 3. GCP Cloud Run v2 声明: content-service 微服务
resource "google_cloud_run_v2_service" "content_uat" {
  name     = "uat-content-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
    containers {
      image = "asia-east1-docker.pkg.dev/${var.gcp_project_id}/serverless/content-service:${var.image_tag}"
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
      env {
        name  = "ENV"
        value = "uat"
      }
      env {
        name  = "DATABASE_URL"
        value = var.supabase_pooler_url
      }
    }
  }
}
