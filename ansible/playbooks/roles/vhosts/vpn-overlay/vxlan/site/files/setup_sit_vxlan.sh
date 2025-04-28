#!/bin/bash
# 多 peer 自动化 VXLAN Overlay 脚本（读取 /etc/vxlan-config.yaml）
# 用法： ./setup_sit_vxlan.sh [reset]

set -e

CONFIG_FILE="/etc/vxlan-config.yaml"
BR_IF="br0"

# 需要 yq 解析 yaml
command -v yq >/dev/null 2>&1 || { echo >&2 "❌ 请安装 yq 命令（https://github.com/mikefarah/yq）"; exit 1; }

if [[ "$1" == "reset" ]]; then
  echo "🔄 正在清理 VXLAN Overlay 配置..."

  # 删除所有 vxlan 接口
  ip -o link show | awk -F': ' '/vxlan[0-9]+/ {print $2}' | while read -r iface; do
    ip link set "$iface" down
    ip link del "$iface"
    echo "🧹 已删除接口 $iface"
  done

  ip link show "$BR_IF" &>/dev/null && {
    ip link set "$BR_IF" down
    ip link del "$BR_IF"
    echo "🧹 已删除桥接器 $BR_IF"
  }

  echo "✅ 清理完成"
  exit 0
fi

# 解析 config
DEV_IF="$(yq e '.dev_if' "$CONFIG_FILE")"
BRIDGE_IP="$(yq e '.bridge_ip' "$CONFIG_FILE")"
CIDR_SUFFIX="$(yq e '.cidr_suffix' "$CONFIG_FILE")"
PEER_COUNT=$(yq e '.peers | length' "$CONFIG_FILE")

if [[ -z "$DEV_IF" || -z "$BRIDGE_IP" || "$PEER_COUNT" -eq 0 ]]; then
  echo "❌ 配置错误：请检查 $CONFIG_FILE"
  exit 1
fi

BRIDGE_CIDR="${BRIDGE_IP}/${CIDR_SUFFIX}"

# 检查 dev_if 是否可用于 VXLAN
function is_vxlan_dev_usable() {
  [[ -d "/sys/class/net/$1" ]] && grep -q "broadcast" "/sys/class/net/$1/flags"
}

echo "🔍 检查 $DEV_IF 是否可用于 VXLAN..."
USE_DEV_PARAM=true
if ! is_vxlan_dev_usable "$DEV_IF"; then
  echo "⚠️  $DEV_IF 不支持广播，将省略 dev 参数（通过路由走隧道）"
  USE_DEV_PARAM=false
fi

# 创建 bridge
if ! ip link show "$BR_IF" &>/dev/null; then
  echo "🛠️ 创建桥接器 $BR_IF"
  ip link add "$BR_IF" type bridge
  ip link set "$BR_IF" up
  ip addr add "$BRIDGE_CIDR" dev "$BR_IF"
fi

# 启用转发
sysctl -w net.ipv4.ip_forward=1

# 遍历 peers
for i in $(seq 0 $((PEER_COUNT - 1))); do
  LOCAL_IP=$(yq e ".peers[$i].local_ip" "$CONFIG_FILE")
  REMOTE_IP=$(yq e ".peers[$i].remote_ip" "$CONFIG_FILE")
  VNI=$(yq e ".peers[$i].vxlan_id" "$CONFIG_FILE")
  MTU=$(yq e ".peers[$i].mtu" "$CONFIG_FILE")
  EXPOSE_PORT=$(yq e ".peers[$i].expose_port" "$CONFIG_FILE")

  VXLAN_IF="vxlan${VNI}"

  echo "🛠️ 创建 VXLAN 接口 $VXLAN_IF (local: $LOCAL_IP, remote: $REMOTE_IP, vni: $VNI)"

  # 清理旧接口
  ip link show "$VXLAN_IF" &>/dev/null && ip link set "$VXLAN_IF" down && ip link del "$VXLAN_IF"

  # 创建 vxlan 接口
  if $USE_DEV_PARAM; then
    ip link add "$VXLAN_IF" type vxlan id "$VNI" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP" dev "$DEV_IF"
  else
    ip link add "$VXLAN_IF" type vxlan id "$VNI" dstport 4789 local "$LOCAL_IP" remote "$REMOTE_IP"
  fi
  ip link set "$VXLAN_IF" mtu "$MTU"
  ip link set "$VXLAN_IF" up
  ip link set "$VXLAN_IF" master "$BR_IF"

  # 可选添加 DNAT
  if [[ -n "$EXPOSE_PORT" && "$EXPOSE_PORT" != "null" ]]; then
    echo "🌐 添加 DNAT 规则：公网:$EXPOSE_PORT → ${BRIDGE_IP}:443"
    iptables -t nat -C PREROUTING -p tcp --dport "$EXPOSE_PORT" -j DNAT --to-destination "${BRIDGE_IP}:443" 2>/dev/null || \
    iptables -t nat -A PREROUTING -p tcp --dport "$EXPOSE_PORT" -j DNAT --to-destination "${BRIDGE_IP}:443"
  fi

done

echo ""
echo "✅ 所有 VXLAN Overlay 配置完成"
