#!/bin/bash
set -x

export version=$1
export cni=$2
export pod_cidr=$3
export svc_cidr=$4

disable_proxy="--disable-kube-proxy"
disable_cni="--flannel-backend=none --disable-network-policy"
default="--disable=traefik,servicelb --data-dir=/opt/rancher/k3s --kube-apiserver-arg service-node-port-range=0-50000"

function setup_k3s()
{
  local extra_opts=$1
  mkdir -pv /opt/rancher/k3s
  
  ping -c 1 google.com > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "当前主机在国际网络上"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$version sh -s - $extra_opts
  else
    echo "当前主机在大陆网络上"
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_VERSION=$version  INSTALL_K3S_MIRROR=cn sh -s - $extra_opts
  fi
  mkdir -pv ~/.kube/ && cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
}

function setup_helm()
{
  ping -c 1 google.com > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "当前主机在国际网络上"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  else
    echo "当前主机在大陆网络上"
    case `uname -m` in
  	x86_64) ARCH=amd64; ;;
          aarch64) ARCH=arm64; ;;
          loongarch64) ARCH=loongarch64; ;;
          *) echo "un-supported arch, exit ..."; exit 1; ;;
    esac
    rm -rf helm.tar.gz* /usr/local/bin/helm || echo true
    sudo wget --no-check-certificate https://mirrors.onwalk.net/tools/linux-${ARCH}/helm.tar.gz && sudo tar -xvpf helm.tar.gz -C /usr/local/bin/
    sudo chmod 755 /usr/local/bin/helm
  fi
}


case $cni in
	'default')  opts="$default" ;;
	'kubeovn')  opts="$default $disable_cni" ;;
	'cilium')   opts="$default $disable_cni $disable_proxy" ;;
        *) echo "error args" ;;
esac

setup_k3s "$opts"
setup_helm
