# VXLAN Overlay 工具集

本目录包含构建与诊断二层 VXLAN Overlay 网络的实用脚本，适用于云主机场景（如 AWS EC2），支持安全模式（保留 eth0 仅用于管理面）。

---

## 🛠️ 脚本列表

| 脚本名称 | 说明 |
|----------|------|
| `setup_sit_vxlan.sh` | 安全模式部署 VXLAN Overlay 网络，仅桥接 `vxlan + veth` |
| `overlay_diag.sh`    | 自动诊断 VXLAN 接口、桥接状态、FDB 转发表、Overlay 连通性 |

---

## 🚀 使用方法

### 1️⃣ 初始化 Overlay 网络

- dev_interface：出口物理网卡（如 ens5）
- local_ip：本机内网 IP（VXLAN 使用）
- remote_ip：对端节点的内网 IP
- br0_ip：本地 Overlay 地址（如 10.255.0.2）
- cidr_suffix（可选）：默认为 16（设置为 /16 子网）
- vxlan_id（可选）：默认 100

示例：  bash setup_sit_vxlan.sh ens5 54.65.102.93 18.179.15.13 10.255.0.2 16 100

### 2️⃣ 诊断 Overlay 网络连通性

示例：

bash overlay_diag.sh <local_overlay_ip> <remote_overlay_ip>
bash overlay_diag.sh 10.255.0.2 10.255.0.3

诊断内容：

- 接口是否存在、是否为 UP 状态；
- br0 IP 是否为非 /32 掩码；
- bridge fdb 是否学习到对端 MAC；
- ping 测试 Overlay 层连通性；
- NAT（MASQUERADE）规则是否存在；
- VXLAN 报文抓包命令提示（UDP port 4789）。

### 📦 典型应用场景

- 构建多节点跨主机的 L2 Overlay 隧道；
- 支持 VXLAN over 公网 IP，内部互通 10.255.0.0/16；
- 云主机或虚拟机跨可用区桥接；
- 上层可用于 gretap、bridge、L2 BGP、广播集群等。
