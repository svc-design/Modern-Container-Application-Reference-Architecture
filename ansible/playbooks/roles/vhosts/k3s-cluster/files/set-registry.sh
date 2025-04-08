#!/bin/bash

#https://github.com/containerd/nerdctl/releases/download/v2.0.2/nerdctl-2.0.2-linux-amd64.tar.gz
#https://github.com/containerd/nerdctl/releases/download/v2.0.2/nerdctl-full-2.0.2-linux-amd64.tar.gz
#wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz

#!/bin/bash
set -e

# =============================================
# ✅ 环境变量检查（可配置）
# =============================================
: "${REGISTRY_DOMAIN:=kube.registry.local}"
: "${REGISTRY_PORT:=5000}"
: "${NERDCTL_VERSION:=v2.0.2}"
: "${CNI_VERSION:=v1.6.2}"
: "${CNI_DIR:=/opt/cni/bin}"
: "${CERT_DIR:=/opt/registry/certs}"
: "${CONFIG_DIR:=/opt/registry/config}"
: "${REGISTRY_DATA:=/var/lib/registry}"
: "${REGISTRY_YAML:=registry.yaml}"
: "${COMPOSE_YAML:=compose.yaml}"
: "${TAR_FILE:=registry.tar}"

# =============================================
# ✅ 自动检测 containerd.sock
# =============================================
if [[ -S "/run/k3s/containerd/containerd.sock" ]]; then
  export CONTAINERD_ADDRESS="/run/k3s/containerd/containerd.sock"
elif [[ -S "/run/containerd/containerd.sock" ]]; then
  export CONTAINERD_ADDRESS="/run/containerd/containerd.sock"
elif [[ -S "/var/run/containerd/containerd.sock" ]]; then
  export CONTAINERD_ADDRESS="/var/run/containerd/containerd.sock"
else
  echo "❌ 未检测到有效的 containerd.sock，请确认 containerd 是否正常运行。"
  exit 1
fi

export NERDCTL_NAMESPACE="k8s.io"

# =============================================
echo "📦 准备 nerdctl 全功能版..."
if ! command -v nerdctl &>/dev/null; then
  if [ ! -f /tmp/nerdctl-full.tgz ]; then
    echo "⬇️ 下载 nerdctl..."
    wget -O /tmp/nerdctl-full.tgz \
      "https://github.com/containerd/nerdctl/releases/download/${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION#v}-linux-amd64.tar.gz"
  else
    echo "📦 已存在 nerdctl-full.tgz，跳过下载"
  fi

  echo "📦 解压 nerdctl 到 /usr/local..."
  sudo tar -C /usr/local -xzf /tmp/nerdctl-full.tgz
  echo "✅ nerdctl 安装完成: $(nerdctl --version)"
else
  echo "✅ nerdctl 已存在: $(nerdctl --version)"
fi

# =============================================
echo "📦 安装 CNI 插件..."
if [ ! -f "${CNI_DIR}/bridge" ]; then
  if [ ! -f /tmp/cni.tgz ]; then
    echo "⬇️ 下载 CNI 插件..."
    wget -O /tmp/cni.tgz \
      "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
  else
    echo "📦 已存在 cni.tgz，跳过下载"
  fi

  sudo mkdir -p "${CNI_DIR}"
  sudo tar -C "${CNI_DIR}" -xzf /tmp/cni.tgz
  echo "✅ CNI 插件已安装到: ${CNI_DIR}"
else
  echo "✅ CNI 插件已存在: ${CNI_DIR}/bridge"
fi

# =============================================
echo "📦 解压 SSL 证书..."

if [ ! -f "ssl_certificates.tar.gz" ]; then
  echo "⬇️ 未找到 ssl_certificates.tar.gz，尝试从 GitHub 下载..."
  wget -O ssl_certificates.tar.gz \
    "https://github.com/svc-design/ansible/releases/download/release-self-signed-cert_kube.registry.local/ssl_certificates.tar.gz" || {
      echo "❌ 无法下载 ssl_certificates.tar.gz，终止执行"
      exit 1
    }
else
  if [ -f "ssl_certificates.tar.gz" ]; then
    mkdir -p "$CERT_DIR"
    tar -xvpf ssl_certificates.tar.gz
    tar -xvpf ssl_certificates.tar.gz -C "$CERT_DIR"
    echo "✅ 证书已解压至: $CERT_DIR"
 fi
fi

# =============================================

# ============ 生成 registry-config ============
echo "⚙️ 准备 registry 配置..."
sudo mkdir -pv "$CONFIG_DIR"
sudo mkdir -pv "$REGISTRY_DATA"
echo "📝 写入 registry-config.yaml..."
sudo cat > "${CONFIG_DIR}/${REGISTRY_YAML}" <<EOF
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :$REGISTRY_PORT
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: /etc/docker/registry/domain.crt
    key: /etc/docker/registry/domain.key
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

echo "✅ 写入完成: $REGISTRY_CONFIG"

# ========== 生成 registry.yaml ==========
echo "🛠️ 生成 registry 配置..."
sudo mkdir -p "$CONFIG_DIR"
cat <<EOF | sudo tee "${CONFIG_DIR}/registry.yaml" > /dev/null
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :${REGISTRY_PORT}
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: /etc/docker/registry/domain.crt
    key: /etc/docker/registry/domain.key
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF
echo "✅ registry.yaml 已创建"

# ========== 生成 compose.yaml ==========
echo "🛠️ 生成 compose 配置..."
cat <<EOF | sudo tee "${CONFIG_DIR}/compose.yaml" > /dev/null
services:
  registry:
    image: registry:latest
    container_name: registry
    restart: always
    network_mode: host
    volumes:
      - /var/lib/registry:/var/lib/registry
      - ${CONFIG_DIR}/registry.yaml:/etc/docker/registry/config.yml
      - ${CERT_DIR}/kube.registry.local.cert:/etc/docker/registry/domain.crt
      - ${CERT_DIR}/kube.registry.local.key:/etc/docker/registry/domain.key
EOF
echo "✅ compose.yaml 已创建"

# =============================================
echo "📦 导入本地 registry 镜像..."
if [ -f "/usr/local/deepflow/$TAR_FILE" ]; then
  sudo CONTAINERD_ADDRESS="$CONTAINERD_ADDRESS" nerdctl --namespace $NERDCTL_NAMESPACE load -i "/usr/local/deepflow/$TAR_FILE"
else
  echo "⚠️ 本地镜像文件不存在：/usr/local/deepflow/$TAR_FILE"
fi

# =============================================
echo "🔁 重启 registry 服务..."
sudo CONTAINERD_ADDRESS="$CONTAINERD_ADDRESS" nerdctl --namespace $NERDCTL_NAMESPACE compose -f "$CONFIG_DIR/compose.yaml" down || true
sudo CONTAINERD_ADDRESS="$CONTAINERD_ADDRESS" nerdctl --namespace $NERDCTL_NAMESPACE compose -f "$CONFIG_DIR/compose.yaml" up -d

# =============================================
echo "🔗 添加 hosts 映射..."
if ! grep -q "$REGISTRY_DOMAIN" /etc/hosts; then
  echo "127.0.0.1 $REGISTRY_DOMAIN" | sudo tee -a /etc/hosts
  echo "✅ /etc/hosts 已添加 $REGISTRY_DOMAIN"
else
  echo "✅ hosts 中已存在 $REGISTRY_DOMAIN"
fi

echo "✅ Registry 启动成功: https://$REGISTRY_DOMAIN:$REGISTRY_PORT"

# =============================================
echo "🔐 安装 CA 证书到系统信任目录..."

CA_CERT="${CERT_DIR}/ca.cert"
if [ ! -f "$CA_CERT" ]; then
  echo "❌ 未找到 CA 证书: $CA_CERT"
else
  if grep -qi "ubuntu\|debian" /etc/os-release; then
    sudo cp "$CA_CERT" "/usr/local/share/ca-certificates/kube-registry-ca.crt"
    sudo update-ca-certificates
    echo "✅ 已导入 CA 到 Ubuntu/Debian 系统信任目录"
  elif grep -qi "rhel\|centos\|rocky" /etc/os-release; then
    sudo cp "$CA_CERT" "/etc/pki/ca-trust/source/anchors/kube-registry-ca.crt"
    sudo update-ca-trust extract
    echo "✅ 已导入 CA 到 RHEL/CentOS 系统信任目录"
  else
    echo "⚠️ 未知发行版，跳过系统 CA 导入"
  fi
fi

# =============================================
echo "🐳 安装 CA 到容器运行时 (Docker/Containerd)..."

# --- Docker CA ---
if command -v docker &>/dev/null; then
  echo "🔧 配置 Docker..."
  DOCKER_CA_DIR="/etc/docker/certs.d/kube.registry.local"
  sudo mkdir -p "$DOCKER_CA_DIR"
  sudo cp "$CA_CERT" "${DOCKER_CA_DIR}/ca.crt"
  echo "✅ 已导入 CA 到 Docker: $DOCKER_CA_DIR"
  sudo systemctl restart docker
fi

# --- Containerd CA ---
if command -v containerd &>/dev/null || [ -S "$CONTAINERD_SOCK" ]; then
  echo "🔧 配置 Containerd..."

  # Alpine/K3s: /etc/containerd/certs.d
  # cri-o/nerdctl: /etc/containerd/certs.d/kube.registry.local/ca.crt
  CONTAINERD_CA_DIR="/etc/containerd/certs.d/kube.registry.local"
  sudo mkdir -p "$CONTAINERD_CA_DIR"
  sudo cp "$CA_CERT" "${CONTAINERD_CA_DIR}/ca.crt"
  echo "✅ 已导入 CA 到 Containerd: $CONTAINERD_CA_DIR"
  sudo systemctl restart containerd || echo "⚠️ containerd 重启失败，可能在 K3s 中不适用"
fi

# --- K3s CA ---
if [[ -S "/run/k3s/containerd/containerd.sock" ]]; then
  echo "🔧 检测到 K3s 环境，准备配置自定义 registry CA..."

  # === 配置参数 ===
  REGISTRY_DOMAIN="kube.registry.local"
  REGISTRY_PORT="5000"
  CA_CERT_PATH="/opt/registry/certs/ca.cert"
  REGISTRIES_YAML="/etc/rancher/k3s/registries.yaml"
  CA_DST_DIR="/etc/rancher/k3s/registries.d/${REGISTRY_DOMAIN}"
  CA_DST_FILE="${CA_DST_DIR}/ca.crt"

  # === 准备目录并拷贝证书 ===
  sudo mkdir -p "${CA_DST_DIR}"
  sudo cp "${CA_CERT_PATH}" "${CA_DST_FILE}"

  # === 写入 registries.yaml ===
  echo "[INFO] 写入 registries.yaml 配置..."
  sudo tee "${REGISTRIES_YAML}" > /dev/null <<EOF
mirrors:
  "${REGISTRY_DOMAIN}:${REGISTRY_PORT}":
    endpoint:
      - "https://${REGISTRY_DOMAIN}:${REGISTRY_PORT}"

configs:
  "${REGISTRY_DOMAIN}:${REGISTRY_PORT}":
    tls:
      ca_file: "${CA_DST_FILE}"
EOF

cat /etc/rancher/k3s/registries.yaml << EOF
mirrors:
  "kube.registry.local:5000":
    endpoint:
      - "http://kube.registry.local:5000"

configs:
  "kube.registry.local:5000":
    tls:
      insecure_skip_verify: true
EOF
      
  # === 重启 K3s 生效 ===
  echo "[INFO] 重启 K3s 服务..."
  if systemctl list-units --type=service | grep -q 'k3s-agent'; then
      sudo systemctl restart k3s-agent
  else
      sudo systemctl restart k3s
  fi

  echo "[✅ SUCCESS] 已配置自定义 registry 并导入 CA：https://${REGISTRY_DOMAIN}:${REGISTRY_PORT}"
fi

