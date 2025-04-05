# VPN Overlay 文档

本项目通过 **WireGuard + VLESS + gretap/VXLAN** 构建跨云、跨平台的大二层互联网络，兼顾穿透、防火墙规避、性能与扩展性。

---

## 一、组网概述：核心协议与封装层级

### 1. WireGuard (WG)
- 类型：L3 VPN（UDP 点对点随身障碍线）
- 用途：形成低负载加密通道

### 2. VLESS + XTLS
- 类型：TLS/gRPC 路由封装协议
- 用途：作为 WireGuard 流量的带容中转

### 3. gretap over WireGuard
- 类型：L2 over L3 over UDP
- 用途：支持二层网络，包括 ARP/广播/DHCP

### 4. VXLAN over WireGuard
- 类型：L2 over UDP
- 用途：适合多 Hub 分区组网和广播

---

## 二、性能、效率、成本、场景对比

| 对比项 | gretap over WG | VXLAN over WG |
|--------|----------------|----------------|
| 封装协议 | GRE (L2 over IP) | VXLAN (L2 over UDP) |
| 架构 | 点对点 | 多点（支持组播） |
| 广播能力 | 完整 L2 广播 | 支持 VXLAN 组播 |
| WG 使用 | gretap 用于 local/remote | VXLAN dev 发包 |
| 多 Hub 扩展 | 差 | 强（VXLAN ID + 组播） |
| 效率 | 高（原生内核支持） | 略低（UDP 重封） |
| 云平台兼容 | 需隔缘 GRE | 要求放行 UDP 4789 |
| MTU | 推荐 1400-1420 | 同上 |
| 平台 | Linux only | 支持 K8s/OpenStack/Linux |

---

## 三、示意结构

### 基本层级
```
[站点主机]
  └─ vxlan100 (L2 Overlay over UDP)
      └─ br0 (虚拟大局域网)
          └─ wg0 (VPN加密接口)
              └─ VLESS 客户端 (XTLS/TCP/GRPC)
                  └─ GFW
                      └─ VLESS 服务端 (公网)
                          └─ WireGuard Hub

### Overlay 网络

```
WG Layer3 网段: 10.100.0.0/24
SiteA.wg0: 10.100.0.2 → WG-Hub: 10.100.0.1 → SiteB.wg0: 10.100.0.3

L2 Bridge br0: 172.16.0.0/16
SiteA.br0: 172.16.1.1
SiteB.br0: 172.16.2.1
```

### 混合组网 (VXLAN + gretap)

```
WG-Hub-1 === VXLAN === WG-Hub-2
   |                        |
 Site A                  Site B
```

---

## 四、配置开关说明 & 自动化逻辑

| 开关 | 默认 | 说明 |
|------|------|------|
| enable_gretap | true | 启用站点到 Hub 的 gretap 连接 |
| enable_vxlan_between_hubs | true | 启用 Hub 间 VXLAN 桥接 |
| enable_vless | true | 站点通过 VLESS 转发 WG 流量 |
| enable_multi_hub | true | 启用多 Hub 组网 |
| only_wireguard | false | 禁用 gretap/VXLAN，仅使用 WG |

**自动化逻辑**
- 如果 vless.enabled: true → 生成 `xray-client.json` + 修改 wg0 endpoint
- gretap 启用 → 生成 br0 框架
- vxlan 启用 → 生成 vxlan100 和 bridge fdb mapping
- only_wireguard = true → 不生成 gretap/VXLAN 结构

---

## 五、VXLAN 多 Hub 实现 (bridge fdb broadcast)

```bash
ip link add vxlan100 type vxlan id 100 dev wg0 dstport 4789 group 239.1.1.100 ttl 10

bridge fdb add 00:00:00:00:00:00 dev vxlan100 dst 10.100.1.1
bridge fdb add 00:00:00:00:00:00 dev vxlan100 dst 10.100.2.1
```

---

## 六、组网演进实践

| 阶段 | 架构 | 开关 | 场景 |
|------|--------|----------------|------|
| 1. P2P | 单点对 | only_wireguard: true | WG 连接测试 |
| 2. Site2Site | 多站 | enable_gretap: true | L2 互联 |
| 3. Net2Net | 多 LAN 桥接 | enable_gretap + br0 | 应用组织 |
| 4. Single Hub | 中心 Hub | enable_multi_hub: true | 合约管理 |
| 5. Double Hub | 双中心 | enable_vxlan_between_hubs: true | 多地区融合 |
| 6. Multi Hub | 多中心 | 全部开 | 大型实施 |

### Step-by-Step

#### 第一步: P2P 模型
- 启用 WG 通信
- 配置 /etc/wireguard/wg0.conf

#### 第二步: 二站 L2 通
- 启用 gretap
- 框架 br0 + 连接 gretap0

#### 第三步: Net2Net
- 多个 LAN 通过 br0 带入 gretap 框架

#### 第四步: Signal Hub
- 各站点 gretap 连接 Hub
- 如有需要同时启用 VLESS

#### 第五步: Double Hub
- Hub 间通过 VXLAN 结合 WG 融合
- 用 bridge fdb 构建组播 VXLAN

#### 第六步: Multi Hub 应用
- 每个 Hub 都搭建 vxlan100 和 br0
- 站点自选最近 Hub
- 支持任意云平台

---

## 七、扩展建议

| 类型 | 内容 |
|------|------|
| 自动部署 | generate_all.sh 一键生成配置 |
| YAML 配置 | 集中 config/sites.yaml |
| 多平台 | 根据 uname 选择 GRE/VXLAN |
| 灾处备份 | 多 Hub 配置切换 |
| 状态监控 | Prometheus 搭配 WG Exporter |

---

> 本项目支持定制化配置，合适各类场景，有关 YAML 配置、服务启动脚本、应用调试相关内容，请连续跟踪项目文档和 config 文件夹。
