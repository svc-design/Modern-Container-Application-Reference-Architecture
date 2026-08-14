# Terraform Module: `serverless_uat`

该模块用于以基础设施即代码（IaC）方式声明和管理基于 GCP Cloud Run (v2) 的 UAT 极简零成本微服务集群：
* `min_instance_count = 0`（无流量自动缩容到 0，闲置零计费）
* `max_instance_count = 2`（限制最大并发实例数，严格防止账单失控）
* 自动注入 Supabase Cloud 连接池与环境参数

## 使用示例

```hcl
module "serverless_uat" {
  source              = "./modules/serverless_uat"
  gcp_project_id      = "ai-workspace-uat-project"
  gcp_region          = "asia-east1"
  image_tag           = "v1.0.0"
  supabase_pooler_url = "postgres://postgres.xxx:pwd@aws-0-asia-east1.pooler.supabase.com:6543/postgres"
}
```
