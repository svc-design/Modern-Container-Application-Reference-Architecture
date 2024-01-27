provider "google" {
 project     = local.config.project_id
 region      = local.config.region
}

terraform {
  backend "gcs" {
    bucket = "iac_google_cloud_terraform_status"  # 替换为你的 GCS 存储桶名称
    prefix = "vhosts/"                     # 根据需要调整前缀
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.74.0"  # 使用适当的版本号
    }
  }
  required_version = ">= 0.14.9"
}
