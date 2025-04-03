#!/bin/bash
# 自动构建 eth + vxlan + br 接口的 overlay 网络，兼容公有云，替代 gretap 实现 L2 over L3
# 用法：
# ./setup_overlay_vxlan.sh <local_ip> <remote_ip> <br0_ip> <eth_iface> [vxlan_id]

set -e

LOCAL_IP="$1"
REMOTE_IP="$2"
BRIDGE_IP="$3"
ETH_IFACE="$4"
VNI="${5:-100}"  # VXLAN ID，默认 100

if [ -z "$LOCAL_IP" ] || [ -z "$REMOTE_IP" ] || [ -z "$BRIDGE_IP" ] || [ -z "$ETH_IFACE" ]; then
  echo "Usage: $0 <local_ip> <remote_ip> <br0_ip> <eth_iface> [vxlan_id]"
  exit 1
fi

VXLAN_IF="vxlan${VNI}"
BR_IF="br0"

echo "🧠 接口名称：$VXLAN_IF（VXLAN ID = $VNI）"

# 清理旧 vxlan 和 br0
for iface in "$VXLAN_IF" "$BR_IF"; do
  if ip link show "$iface" &>/dev/null; then
    echo "🧹 清理旧接口 $iface..."
    ip link set "$iface" down || true
    ip addr flush dev "$iface" || true
    ip link del "$iface" || true
    sleep 1
  fi
done

echo "[1] 创建 VXLAN 接口：$VXLAN_IF"
ip link add "$VXLAN_IF" type vxlan id "$VNI" dev "$ETH_IFACE" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP"
ip link set "$VXLAN_IF" up

echo "[2] 创建桥接设备 $BR_IF 并加入 $VXLAN_IF + $ETH_IFACE"
ip link add "$BR_IF" type bridge
ip link set "$VXLAN_IF" master "$BR_IF"
ip link set "$ETH_IFACE" master "$BR_IF"

echo "[3] 配置 $BR_IF 地址为 $BRIDGE_IP"
ip addr add "$BRIDGE_IP" dev "$BR_IF"
ip link set "$BR_IF" up

echo "[4] 启用 IP 转发（可选，仅透传场景需要）"
sysctl -w net.ipv4.ip_forward=1

echo "[5] 设置 SNAT（如需让 Overlay 网络流量出网）"
iptables -t nat -C POSTROUTING -s 172.16.0.0/16 -o "$ETH_IFACE" -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -o "$ETH_IFACE" -j MASQUERADE

echo "✅ Overlay 网络已完成："
echo "  - vxlan: $VXLAN_IF"
echo "  - bridge: $BR_IF with IP $BRIDGE_IP"
