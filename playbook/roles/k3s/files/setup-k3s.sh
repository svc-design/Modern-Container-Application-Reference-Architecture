#!/bin/bash
set -x

export version=$1
export cluster_domain=$2
export cni=$3
export ingress=$4
export pod_cidr=$5
export svc_cidr=$6

function set_k3s_default()
{
  mkdir -pv /opt/rancher/k3s
  
  ping -c 1 google.com > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "当前主机在国际网络上"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$version sh -s - \
  	--disable=traefik,servicelb                          \
  	--cluster-domain=$cluster_domain                     \
	--cluster-cidr=$pod_cidr                             \
	--service-cidr=$svc_cidr                             \
  	--write-kubeconfig-mode 644                          \
  	--write-kubeconfig ~/.kube/config                    \
  	--data-dir=/opt/rancher/k3s                          \
  	--kube-apiserver-arg service-node-port-range=0-50000
  else
    echo "当前主机在大陆网络上"
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_VERSION=$version  INSTALL_K3S_MIRROR=cn sh -s - \
  	--disable=traefik,servicelb                          \
  	--cluster-domain=$cluster_domain                     \
	--cluster-cidr=$pod_cidr                             \
	--service-cidr=$svc_cidr                             \
  	--write-kubeconfig-mode 644                          \
  	--write-kubeconfig ~/.kube/config                    \
  	--data-dir=/opt/rancher/k3s                          \
  	--kube-apiserver-arg service-node-port-range=0-50000
  fi
}

function set_k3s_cni_kubevon()
{
  mkdir -pv /opt/rancher/k3s

  ping -c 1 google.com > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "当前主机在国际网络上"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$version sh -s - \
	--disable=traefik,servicelb                          \
	--cluster-domain=$cluster_domain                     \
	--cluster-cidr=$pod_cidr                             \
	--service-cidr=$svc_cidr                             \
	--write-kubeconfig-mode 644                          \
        --flannel-backend=none                               \
	--disable-network-policy                             \
	--write-kubeconfig ~/.kube/config                    \
	--data-dir=/opt/rancher/k3s                          \
	--kube-apiserver-arg service-node-port-range=0-50000
  else
    echo "当前主机在大陆网络上"
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_VERSION=$version  INSTALL_K3S_MIRROR=cn sh -s - \
	--disable=traefik,servicelb                          \
	--cluster-domain=$cluster_domain                     \
	--cluster-cidr=$pod_cidr                             \
	--service-cidr=$svc_cidr                             \
        --flannel-backend=none                               \
	--disable-network-policy                             \
	--write-kubeconfig-mode 644                          \
	--write-kubeconfig ~/.kube/config                    \
	--data-dir=/opt/rancher/k3s                          \
	--kube-apiserver-arg service-node-port-range=0-50000
  fi
}

## __main__ ##
#
if [[ $cni == 'default' ]]; then
  set_k3s_default
elif [[ $cni == 'kubeovn' ]]; then
  set_k3s_cni_kubevon
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
case `uname -m` in
	x86_64) ARCH=amd64; ;;
        aarch64) ARCH=arm64; ;;
        loongarch64) ARCH=loongarch64; ;;
        *) echo "un-supported arch, exit ..."; exit 1; ;;
esac
rm -rf helm.tar.gz* /usr/local/bin/helm || echo true
sudo wget --no-check-certificate https://mirrors.onwalk.net/tools/linux-${ARCH}/helm.tar.gz && sudo tar -xvpf helm.tar.gz -C /usr/local/bin/
sudo chmod 755 /usr/local/bin/helm

helm repo add artifact https://artifact.onwalk.net/chartrepo/public/ | echo true
helm repo up
