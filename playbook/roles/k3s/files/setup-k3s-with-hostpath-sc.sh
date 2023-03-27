mkdir -pv /opt/rancher/k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.7+k3s1 sh -s - \
	--disable=traefik                                    \
	--flannel-backend=none                               \
	--disable-network-policy                             \
	--write-kubeconfig-mode 644                          \
	--write-kubeconfig ~/.kube/config                    \
	--data-dir=/opt/rancher/k3s                          \
	--kube-apiserver-arg service-node-port-range=0-50000

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

helm install cilium cilium/cilium --version 1.13.1 \
  --namespace kube-system \
  --set global.kubeProxyReplacement=strict \
  --set global.masquerade=false \
  --set global.nodePort.enabled=true \
  --set global.tunnel=disabled \
  --set nodeinit.enabled=true \
  --set nodeinit.reconfigureKubelet=true \
  --set cni.binPath=/opt/cni/bin \
  --set cni.customConf=true \
  --set cni.confTemplate=/etc/cilium/cilium-cni.conf.tmpl \
  --set hubble.enabled=true \
  --set hubble.listenAddress=":4244" \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}"

helm repo add artifact https://artifact.onwalk.net/chartrepo/k8s/ | echo true
helm repo up
