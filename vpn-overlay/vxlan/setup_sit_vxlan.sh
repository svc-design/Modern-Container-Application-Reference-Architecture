#!/bin/bash
# 安全版 VXLAN Overlay 脚本：保留 eth0 做管理面，仅桥接 vxlan0 + vethX
# 用法：
# ./setup_overlay_safe.sh <local_ip> <remote_ip> <br0_ip> <vxlan_id>

set -e

LOCAL_IP="$1"
REMOTE_IP="$2"
BRIDGE_IP="$3"
VNI="${4:-100}"  # VXLAN ID，默认 100

if [ -z "$LOCAL_IP" ] || [ -z "$REMOTE_IP" ] || [ -z "$BRIDGE_IP" ]; then
  echo "Usage: $0 <local_ip> <remote_ip> <br0_ip> [vxlan_id]"
  exit 1
fi

VXLAN_IF="vxlan${VNI}"
BR_IF="br0"
VETH_A="veth_overlay"
VETH_B="veth_peer"

echo "🧠 安全模式：仅桥接 $VXLAN_IF 和 $VETH_B，不动 eth0"

# 清理旧接口
for iface in "$VXLAN_IF" "$BR_IF" "$VETH_A" "$VETH_B"; do
  if ip link show "$iface" &>/dev/null; then
    echo "🧹 删除旧接口 $iface..."
    ip link set "$iface" down || true
    ip link del "$iface" || true
  fi
done

# 创建 VXLAN 接口
echo "[1] 创建 VXLAN 接口：$VXLAN_IF"
ip link add "$VXLAN_IF" type vxlan id "$VNI" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP"
ip link set "$VXLAN_IF" up

# 创建 veth pair 模拟数据交换接口
echo "[2] 创建 veth pair：$VETH_A <-> $VETH_B"
ip link add "$VETH_A" type veth peer name "$VETH_B"
ip link set "$VETH_A" up
ip link set "$VETH_B" up

# 创建桥接 br0
echo "[3] 创建 br0 桥接设备"
ip link add "$BR_IF" type bridge
ip link set "$VXLAN_IF" master "$BR_IF"
ip link set "$VETH_B" master "$BR_IF"
ip link set "$BR_IF" up

# 分配 BRIDGE IP
echo "[4] 配置 br0 地址：$BRIDGE_IP"
ip addr add "$BRIDGE_IP" dev "$BR_IF"

# 可选 SNAT 出口（若该主机需要 NAT 功能）
echo "[5] 启用 IP 转发 + SNAT（可选）"
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -s 10.255.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s 10.255.0.0/16 -o eth0 -j MASQUERADE

echo "✅ 安全 Overlay 构建完成："
echo "  - vxlan: $VXLAN_IF"
echo "  - bridge: $BR_IF  (IP: $BRIDGE_IP)"
echo "  - 管理面未修改 eth0，可正常连通"
