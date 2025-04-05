#!/bin/bash
# overlay_diag.sh - VXLAN Overlay 自动诊断工具（Pro 版）

set -e

if [ $# -ne 2 ]; then
  echo "用法: $0 <local_overlay_ip> <remote_overlay_ip>"
  exit 1
fi

LOCAL_IP="$1"
REMOTE_IP="$2"
BR_IF="br0"
VETH_A="veth_overlay"
VETH_B="veth_peer"
VXLAN_IF=$(ip -o link show | grep -o 'vxlan[0-9]\+' | head -n 1)
VXLAN_ID=$(echo "$VXLAN_IF" | grep -o '[0-9]\+')

echo "============================"
echo "🔍 VXLAN Overlay 网络诊断工具"
echo "============================"
echo "📍 本地 Overlay IP: $LOCAL_IP"
echo "📍 对端 Overlay IP: $REMOTE_IP"
echo "📦 VXLAN 接口: $VXLAN_IF"
echo "🆔 VXLAN ID: $VXLAN_ID"
echo ""

# 接口存在性检测
for iface in "$VXLAN_IF" "$VETH_A" "$VETH_B" "$BR_IF"; do
  if ip link show "$iface" &>/dev/null; then
    echo "✅ 接口 $iface 存在"
  else
    echo "❌ 接口 $iface 不存在"
  fi
done
echo ""

# 接口 UP 状态
for iface in "$VXLAN_IF" "$VETH_A" "$VETH_B" "$BR_IF"; do
  state=$(cat /sys/class/net/$iface/operstate 2>/dev/null || echo "unknown")
  echo "📶 接口 $iface 状态: $state"
done
echo ""

# br0 IP 信息
br0_ip=$(ip -4 addr show "$BR_IF" | grep -oP 'inet \K[\d.]+/\d+')
if [[ "$br0_ip" == */32 ]]; then
  echo "⚠️  br0 IP 为 /32：$br0_ip → 建议设置为 /16 或其他实际子网"
else
  echo "✅ br0 IP 设置为：$br0_ip"
fi
echo ""

# FDB 表
echo "📡 FDB 转发表 (bridge fdb show dev $VXLAN_IF)："
bridge fdb show dev "$VXLAN_IF"
echo ""

# ping 连通性测试
echo "🔁 ping 对端 Overlay IP: $REMOTE_IP（从 $VETH_A 发起）"
ping -c 3 -I "$VETH_A" "$REMOTE_IP" || echo "⚠️  ping 失败，可能未打通 VXLAN 或对端未启动"
echo ""

# iptables SNAT 检查
echo "🧱 iptables NAT 规则检查（是否有 MASQUERADE）："
iptables -t nat -S POSTROUTING | grep MASQUERADE || echo "⚠️  没有检测到 MASQUERADE 规则"
echo ""

# 抓包提示
echo "🔬 VXLAN 报文检测提示（需 root 权限）："
echo "👉 可运行以下命令查看 VXLAN 报文是否流动："
echo "   sudo tcpdump -ni $VXLAN_IF udp port 4789"
echo "   sudo tcpdump -ni $VETH_B"
echo "   sudo tcpdump -ni $BR_IF"
echo ""

echo "📌 若 ping 不通但 FDB 存在，可能为对端未配置、未学习或防火墙阻断。"
echo "✅ 诊断完成！"
