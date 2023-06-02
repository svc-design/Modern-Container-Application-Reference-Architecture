#!/bin/bash

wget https://raw.githubusercontent.com/kubeovn/kube-ovn/release-1.10/dist/images/cleanup.sh
bash cleanup.sh

rm -rf /var/run/openvswitch
rm -rf /var/run/ovn
rm -rf /etc/origin/openvswitch/
rm -rf /etc/origin/ovn/
rm -rf /etc/cni/net.d/00-kube-ovn.conflist
rm -rf /etc/cni/net.d/01-kube-ovn.conflist
rm -rf /var/log/openvswitch
rm -rf /var/log/ovn
rm -fr /var/log/kube-ovn

/usr/local/bin/k3s-uninstall.sh
rm -rvf /opt/rancher/ /etc/rancher/ /var/lib/rancher/ ~/.kube

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
