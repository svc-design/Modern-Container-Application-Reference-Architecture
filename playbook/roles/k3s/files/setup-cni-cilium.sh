
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

helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.10.4 \
   --namespace kube-system\
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
