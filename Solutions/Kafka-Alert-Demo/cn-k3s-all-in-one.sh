sudo mkdir -pv /opt/rancher/k3s
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_SKIP_SELINUX_RPM=true sh -s - \
--system-default-registry "registry.cn-hangzhou.aliyuncs.com" --data-dir=/opt/rancher/k3s --kube-apiserver-arg service-node-port-range=0-50000 --disable=traefik,servicelb
#curl -sfL https://get.k3s.io | sh -s - --disable=traefik,servicelb                                   \
#        --data-dir=/opt/rancher/k3s                                                                  \
#        --kube-apiserver-arg service-node-port-range=0-50000

sudo mkdir -pv ~/.kube/
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

sudo snap install helm --classic
