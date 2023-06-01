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
rm -rvf /opt/rancher/ /etc/rancher/ /var/lib/rancher/
