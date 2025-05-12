目标是实现：

Pod 从 deepflow-demo-k3s 发起访问，跨越 cn-hub-k3s 中转，到达 global-hub-k3s 的服务，支持跨集群的 L3 层流量调度（出站 + 路由 + VXLAN 封装）

[POD A: deepflow-demo-k3s]
   │
   ▼ SNAT (to 10.253.255.100)
[Egress Node @ deepflow-demo-k3s]
   │ VXLAN Tunnel
   ▼
[Relay Hub: cn-hub-k3s]
   │ VXLAN Mesh
   ▼
[global-hub-k3s Service: 10.253.254.x]



## 1. Cluster Role Planning

| Cluster Name         | Type     | Connection Mode       | Node Name      | VXLAN Bridge IP (`br_ip`)  |  WireGuard IP (`wg_ip`) |
|----------------------|----------|-----------------------|----------------|------------------------ -|-----------------------|
| `cn-hub-k3s`         | Hub        | CN Hub                | `cn-hub`         | `10.253.253.1`             | `172.30.0.1`            |
| `global-hub-k3s`     | Hub        | Global Hub            | `global-hub`     | `10.253.254.1`             | `172.31.0.1`            |
| `deepflow-demo-k3s`  | Site       | Connects to CN Hub    | `deepflow-demo`  | `10.253.253.2`             | `172.30.0.10`           |


流量调度流程拆解

1. Pod in deepflow-demo-k3s → 发起请求到 10.253.254.20
2. Cilium Egress NAT → 将源地址 SNAT 为 10.253.255.100
3. VXLAN over WireGuard → VXLAN 封装从 deepflow-demo → cn-hub
4. VXLAN Mesh → cn-hub → 转发到 global-hub
5. 目标服务响应 → global-hub 的服务接收流量，返回数据走回原通道

核心组件协同（最小集成）
层级	技术	功能
L3	Cilium Egress Gateway	控制 Pod → SNAT 出站 IP
L2.5	VXLAN + WireGuard	跨集群隧道封装、可穿透中转
L7（可选）	Kong Gateway	可在 global-hub 接入层控制 L7 路由


# Cilium EgressGateway 安装与配置


# CiliumEgressGatewayPolicy 示例

apiVersion: cilium.io/v2alpha1
kind: CiliumEgressGatewayPolicy
metadata:
  name: deepflow-to-globalhub
spec:
  egress:
    - podSelector:
        matchLabels:
          app: deepflow-agent
      destinationCIDRs:
        - 10.253.254.0/24
      egressGateway:
        nodeSelector:
          matchLabels:
            egress-gateway: cilium
        ip: 10.253.255.100
