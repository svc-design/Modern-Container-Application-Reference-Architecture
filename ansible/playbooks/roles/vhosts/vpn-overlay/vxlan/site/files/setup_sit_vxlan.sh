#!/bin/bash
# 安全增强版 VXLAN Overlay 脚本（支持 wg0 作为通道设备）
# 用法： ./setup_sit_vxlan.sh <dev_if> <local_ip> <remote_ip> <br0_ip> [cidr_suffix] [vxlan_id] [mtu]

set -e

DEV_IF="$1"
LOCAL_IP="$2"
REMOTE_IP="$3"
BRIDGE_IP="$4"
CIDR_SUFFIX="${5:-16}"
VNI="${6:-100}"
MTU="${7:-1400}"

if [[ -z "$DEV_IF" || -z "$LOCAL_IP" || -z "$REMOTE_IP" || -z "$BRIDGE_IP" ]]; then
  echo "Usage: $0 <dev_if> <local_ip> <remote_ip> <br0_ip> [cidr_suffix] [vxlan_id] [mtu]"
  exit 1
fi

VXLAN_IF="vxlan${VNI}"
BR_IF="br0"
BRIDGE_CIDR="${BRIDGE_IP}/${CIDR_SUFFIX}"
SUBNET="$(echo "$BRIDGE_IP" | cut -d. -f1-2).0.0/${CIDR_SUFFIX}"

# 自动判断 dev 是否能用于 VXLAN（需支持广播）
function is_vxlan_dev_usable() {
  [[ -d "/sys/class/net/$1" ]] && grep -q "broadcast" "/sys/class/net/$1/flags"
}

echo "🔍 检查 $DEV_IF 是否可用于 VXLAN..."
USE_DEV_PARAM=true
if ! is_vxlan_dev_usable "$DEV_IF"; then
  echo "⚠️  $DEV_IF 不支持广播，将省略 dev 参数（通过路由走隧道）"
  USE_DEV_PARAM=false
fi

# 清理旧接口
for iface in "$VXLAN_IF" "$BR_IF"; do
  ip link show "$iface" &>/dev/null && ip link set "$iface" down && ip link del "$iface"
done

# 创建 VXLAN 接口
echo "🛠️ 创建 VXLAN 接口 $VXLAN_IF ..."
if $USE_DEV_PARAM; then
  ip link add "$VXLAN_IF" type vxlan id "$VNI" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP" dev "$DEV_IF"
else
  ip link add "$VXLAN_IF" type vxlan id "$VNI" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP"
fi
ip link set "$VXLAN_IF" mtu "$MTU"
ip link set "$VXLAN_IF" up

# 创建 br0 桥
ip link add "$BR_IF" type bridge
ip link set "$BR_IF" mtu "$MTU"
ip link set "$VXLAN_IF" master "$BR_IF"
ip link set "$BR_IF" up

# 配置 IP
ip addr add "$BRIDGE_CIDR" dev "$BR_IF"

# 启用转发 + SNAT（仅主机出网时）
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$DEV_IF" -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$DEV_IF" -j MASQUERADE

# 尝试激活邻居学习
REMOTE_BR_IP="172.16.0.$(( $(echo "$BRIDGE_IP" | awk -F. '{print $4}') == 2 ? 3 : 2 ))"
ping -c 1 "$REMOTE_BR_IP" || true

# 展示结果
echo ""
echo "✅ VXLAN Overlay 已建立"
echo "  - bridge: $BR_IF ($BRIDGE_CIDR)"
echo "  - vxlan: $VXLAN_IF ($LOCAL_IP ⇄ $REMOTE_IP, id=$VNI, mtu=$MTU)"
echo "  - SNAT: $SUBNET → $DEV_IF"

