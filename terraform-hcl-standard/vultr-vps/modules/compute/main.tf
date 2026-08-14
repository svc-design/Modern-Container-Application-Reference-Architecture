variable "label" {
  description = "实例名称"
  type        = string
}

variable "region" {
  description = "Vultr 区域代码"
  type        = string
}

variable "plan" {
  description = "Vultr 计费套餐 (例如 vc2-1c-1gb)"
  type        = string
}

variable "os_id" {
  description = "操作系统 ID，参考 Vultr 文档 (例：215 为 Ubuntu 22.04)"
  type        = number
}

variable "enable_ipv6" {
  description = "是否启用 IPv6"
  type        = bool
  default     = true
}

variable "backups" {
  description = <<-EOT
    是否为该实例启用自动备份。

    注意: 这个开关不由 vultr_instance 直接执行, 见下方 resource 里的说明。
    渲染层把它写进 hosts_manifest.json, 由 apply 之后的幂等对账步骤
    (platform-ops_provision_reconcile-backup-schedules.sh) 调 Vultr API 落实。
  EOT
  type        = bool
  default     = false
}

variable "backups_schedule" {
  description = "自动备份计划（UTC）；与 var.backups 一样由 apply 后的对账步骤落实"
  type = object({
    type = string
    hour = number
    dow  = optional(number)
    dom  = optional(number)
  })
  default = {
    type = "daily"
    hour = 5
  }
}

variable "tags" {
  description = "实例标签列表"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "可选的 VPC ID，将实例加入私网"
  type        = string
  default     = null
}

variable "ssh_key_ids" {
  description = "已上传的 SSH Key ID 列表"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "cloud-init 用户数据"
  type        = string
  default     = ""
}

variable "snapshot_id" {
  description = "Vultr 自定义快照 ID (Golden Image)，优先于 os_id"
  type        = string
  default     = null
}

# 备份计划刻意不在这里声明 —— 这不是偷懒, 是绕开一个会污染 state 的
# provider 缺陷:
#
# vultr provider 的 Create 在实例 status=active 之后紧接着调
# PUT /v2/instances/{id}/backup-schedule。Vultr 侧此时实例常常还没在
# 备份子系统里注册完, 返回 {"error":"Invalid instance-id.","status":404},
# 于是 Create 以 "error setting backup schedule" 失败 —— 但实例已经建出来
# 了, 它的 ID 也已经 SetId() 进了 state。结果是一条半成品记录: 资源存在于
# state, 云上却处在一个我们没有走完创建流程的状态。人一旦手工清掉那台机器
# (或它本就被回滚), state 里就留下一个指向已删实例的孤儿 ID, 而 2.21.0 的
# Read 只把 "invalid instance ID" 当作 gone, 对 "instance not found" 这个
# 措辞直接抛错, 于是之后每一次 plan 都在 refresh 阶段硬失败, 整条流水线
# 卡死在 provision, 且重跑不会自愈。
#
# 因此: 实例恒以 backups=disabled 创建(创建期不再有 backup-schedule 调用),
# 备份由 apply 之后的幂等对账步骤按 hosts_manifest.json 落实。ignore_changes
# 保证那一步把备份打开后, 下一次 plan 不会再把它改回 disabled。
resource "vultr_instance" "this" {
  label       = var.label
  region      = var.region
  plan        = var.plan
  os_id       = (var.snapshot_id != null && var.snapshot_id != "") ? null : var.os_id
  snapshot_id = (var.snapshot_id != null && var.snapshot_id != "") ? var.snapshot_id : null
  enable_ipv6 = var.enable_ipv6
  backups     = "disabled"
  tags        = var.tags
  vpc_ids     = var.vpc_id == null ? [] : [var.vpc_id]
  ssh_key_ids = var.ssh_key_ids
  user_data   = var.user_data

  lifecycle {
    ignore_changes = [backups, backups_schedule]
  }
}

output "instance_id" {
  value       = vultr_instance.this.id
  description = "实例 ID"
}

output "main_ip" {
  value       = vultr_instance.this.main_ip
  description = "主公网 IP"
}

output "default_password" {
  value       = vultr_instance.this.default_password
  description = "系统生成密码（如未使用 SSH Key 时）"
  sensitive   = true
}
