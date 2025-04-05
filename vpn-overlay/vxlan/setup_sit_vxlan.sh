#!/bin/bash
# 安全版 VXLAN Overlay 脚本（参数顺序改为 dev_if + ip 信息）

set -e

DEV_IF="$1"
LOCAL_IP="$2"
REMOTE_IP="$3"
BRIDGE_IP="$4"
CIDR_SUFFIX="${5:-16}"
VNI="${6:-100}"

if [ -z "$DEV_IF" ] || [ -z "$LOCAL_IP" ] || [ -z "$REMOTE_IP" ] || [ -z "$BRIDGE_IP" ]; then
  echo "Usage: $0 <dev_interface> <local_ip> <remote_ip> <br0_ip> [cidr_suffix] [vxlan_id]"
  exit 1
fi

VXLAN_IF="vxlan${VNI}"
BR_IF="br0"
VETH_A="veth_overlay"
VETH_B="veth_peer"
BRIDGE_CIDR="${BRIDGE_IP}/${CIDR_SUFFIX}"
SUBNET="$(echo "$BRIDGE_IP" | cut -d. -f1-2).0.0/${CIDR_SUFFIX}"

echo "🧠 安全模式：仅桥接 $VXLAN_IF 和 $VETH_B，不动 $DEV_IF"

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
ip link add "$VXLAN_IF" type vxlan id "$VNI" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP" dev "$DEV_IF"
ip link set "$VXLAN_IF" up

# 创建 veth pair
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

# 配置 IP 和子网掩码
echo "[4] 配置 br0 地址：$BRIDGE_CIDR"
ip addr add "$BRIDGE_CIDR" dev "$BR_IF"

# 启用 SNAT
echo "[5] 启用 IP 转发 + SNAT（出口：$DEV_IF，子网：$SUBNET）"
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$DEV_IF" -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$DEV_IF" -j MASQUERADE

# 自动触发 ARP 学习
REMOTE_LAST_OCTET="$(echo "$REMOTE_IP" | awk -F. '{print $4}')"
if [[ "$REMOTE_LAST_OCTET" -eq 2 ]]; then
  REMOTE_BR_IP="10.255.0.3"
else
  REMOTE_BR_IP="10.255.0.2"
fi

echo "[6] 触发 ARP 学习 ping：$REMOTE_BR_IP ← from $VETH_A"
ping -c 1 -I "$VETH_A" "$REMOTE_BR_IP" || true

echo "✅ 安全 Overlay 构建完成："
echo "  - vxlan: $VXLAN_IF"
echo "  - bridge: $BR_IF  (IP: $BRIDGE_CIDR)"
echo "  - SNAT 子网：$SUBNET → $DEV_IF"
