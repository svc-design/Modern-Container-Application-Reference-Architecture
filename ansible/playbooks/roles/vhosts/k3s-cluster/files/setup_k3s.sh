#!/bin/bash
set -e

# === 必要参数 ===
INSTALL_K3S_URL="https://get.k3s.io"
FLANNEL_IFACE=${FLANNEL_IFACE:-br0}

# === 安装命令拼接（最简）===
INSTALL_K3S_EXEC="server \
  --disable=traefik,servicelb,local-storage \
  --data-dir=/opt/rancher/k3s \
  --advertise-address=$(hostname -I | awk '{print $1}') \
  --kube-apiserver-arg=service-node-port-range=0-50000"

[[ -n "$FLANNEL_IFACE" ]] && INSTALL_K3S_EXEC+=" --flannel-iface=${FLANNEL_IFACE}"

# === 下载并执行安装 ===
curl -sfL ${INSTALL_K3S_URL} -o install_k3s.sh && chmod +x install_k3s.sh
INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" ./install_k3s.sh

# === 等待 CoreDNS 启动 ===
echo "⏳ 等待 CoreDNS 启动..."
until kubectl get pods -A 2>/dev/null | grep -q "coredns.*Running"; do
  sleep 3
done

# === 设置本地 kubeconfig ===
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "✅ K3s 安装完成，kubectl/helm 已就绪"


