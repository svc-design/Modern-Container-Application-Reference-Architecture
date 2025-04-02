#!/bin/bash

VXLAN_ID=100
VXLAN_DEV=vxlan100
WG_DEV=wg0
BRIDGE=br0

# 本地 WG IP
LOCAL_IP=10.100.0.1

# 远端 Hub WG IPs（去掉本地）
PEERS=(
  10.100.1.1
  10.100.2.1
)

# 创建 VXLAN
ip link add $VXLAN_DEV type vxlan id $VXLAN_ID dev $WG_DEV dstport 4789 local $LOCAL_IP
ip link set $VXLAN_DEV up

# 添加静态 FDB 映射
for PEER_IP in "${PEERS[@]}"; do
  bridge fdb add 00:00:00:00:00:00 dev $VXLAN_DEV dst $PEER_IP
done

# 添加进 br0
brctl addif $BRIDGE $VXLAN_DEV

