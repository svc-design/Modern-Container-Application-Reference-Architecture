#!/bin/bash
export NodeIP=$1
node_name=`hostname`

modprobe geneve
modprobe openvswitch
modprobe ip_tables
modprobe iptable_nat

rm -rvf /etc/cni/net.d/*

# 移除cni命名空间
ip netns show 2>/dev/null | grep cni- | xargs -r -t -n 1 ip netns delete
# 移除cnio网卡
ip link show 2>/dev/null | grep 'master cni0' | while read ignore iface ignore; do
    iface=${iface%%@*}
    [ -z "$iface" ] || ip link delete $iface
done
ip link delete cni0
ip link delete flannel.1
rm -rf /var/lib/cni/
# 清理iptables
iptables-save | grep -v KUBE- | grep -v CNI- | iptables-restore

kubectl taint node $node_name node-role.kubernetes.io/control-plane:NoSchedule-
kubectl label node $node_name kubernetes.io/os=linux --overwrite
kubectl label node $node_name kube-ovn/role=master --overwrite
helm repo add kubeovn https://kubeovn.github.io/kube-ovn/
helm repo up
helm upgrade --install kube-ovn kubeovn/kube-ovn --set MASTER_NODES=${NodeIP} -n kube-system
