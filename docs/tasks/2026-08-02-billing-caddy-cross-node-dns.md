# Billing Caddy 跨节点 DNS 声明

`web-saas` 主机上的 Caddy 为 agent-proxy 提供受源 IP 限制的 Billing job
入口。这里仅声明 DNS 记录，真正是否渲染站点由 playbooks 根据
`WEB_SAAS_BILLING_DOMAIN` 与 `WEB_SAAS_BILLING_ALLOWED_CIDRS` 决定。

- UAT：`billing-uat.<TARGET_DOMAIN_BASE>`；

本次只增加 UAT DNS 记录；生产不增加 Billing 外部入口，也不改变生产
`BILLING_SERVICE_BASE_URL`。

这样 DNS、Caddy、agent `billing.baseURL` 三者使用同一域名契约，避免出现“Caddy
已有路由但域名没有 A 记录”的半通状态。
