#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# ========== 默认参数 ==========
DEFAULT_ENV="sit"
DEFAULT_CONFIG="${PROJECT_ROOT}/config"

# ========== 模块路径 ==========
PULUMI_DIR="${PROJECT_ROOT}/iac_modules/pulumi"
TERRAFORM_DIR="${PROJECT_ROOT}/iac_modules/terraform"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"


# ================================
# ✅ 自动加载 Pulumi passphrase
# ================================
export PULUMI_CONFIG_PASSPHRASE_FILE="${PULUMI_CONFIG_PASSPHRASE_FILE:-$HOME/.pulumi-passphrase}"

if [ ! -f "$PULUMI_CONFIG_PASSPHRASE_FILE" ]; then
  echo "⚠️  未检测到 Pulumi 密码文件: $PULUMI_CONFIG_PASSPHRASE_FILE"
  echo "请先创建该文件并写入 passphrase，例如："
  echo "  echo 'changeme123' > ~/.pulumi-passphrase && chmod 600 ~/.pulumi-passphrase"
  exit 1
else
  echo "🔐 Pulumi 密码文件已加载: $PULUMI_CONFIG_PASSPHRASE_FILE"
fi

# ========== 参数解析 ==========
if [[ -n "$1" && "$1" != up && "$1" != down && "$1" != delete && "$1" != export && "$1" != import && "$1" != init && "$1" != ansible && "$1" != help ]]; then
  STACK_ENV="$1"
  ACTION="${2:-up}"
else
  STACK_ENV="${STACK_ENV:-$DEFAULT_ENV}"
  ACTION="${1:-help}"
fi

STACK_NAME="${STACK_NAME:-$STACK_ENV}"
CONFIG_PATH="${CONFIG_PATH:-${DEFAULT_CONFIG}/${STACK_ENV}}"

# ========== 配置目录检查 ==========
if [ ! -d "$CONFIG_PATH" ] || [ -z "$(find "$CONFIG_PATH" -maxdepth 1 -name '*.yml' -o -name '*.yaml')" ]; then
  echo "⚠️ 配置目录为空：$CONFIG_PATH，跳过部署"
  exit 0
fi

# ========== 帮助信息 ==========
print_help() {

  echo ""
  echo "🧰 iac_cli - 多环境自动化管理器 (IaC + Ansible + GitOps)"
  echo ""

  echo "用法:"
  echo "  ./scripts/run.sh [env] [命令]"
  echo "  STACK_ENV=prod CONFIG_PATH=config/prod ./scripts/run.sh up"
  echo ""
  echo "🌍 当前环境: $STACK_ENV"
  echo "📁 当前配置路径: $CONFIG_PATH"
  echo ""
  echo "支持命令:"
  echo "  init      ⚙️ 初始化依赖"
  echo "  up        🚀 部署资源"
  echo "  down      🔥 销毁资源"
  echo "  export    📤 导出 stack 状态"
  echo "  import    📥 导入 stack 状态"
  echo "  ansible   🧪 执行 ansible-playbook"
  echo "  help      📖 显示帮助"
  echo ""
}

# ========== 检查 Pulumi ==========
ensure_pulumi() {
  if ! command -v pulumi &> /dev/null; then
    echo "📦 未检测到 Pulumi，正在自动安装..."
    case "$(uname | tr '[:upper:]' '[:lower:]')" in
      linux)
        curl -fsSL https://get.pulumi.com | sh
        export PATH="$HOME/.pulumi/bin:$PATH"
        ;;
      darwin)
        brew install pulumi || (curl -fsSL https://get.pulumi.com | sh && export PATH="$HOME/.pulumi/bin:$PATH")
        ;;
      msys*|mingw*|cygwin*)
        echo "👉 Windows 用户请手动安装 Pulumi：https://www.pulumi.com/docs/get-started/install/"
        exit 1
        ;;
      *)
        echo "❌ 当前平台不支持自动安装 Pulumi"
        exit 1
        ;;
    esac
  fi
  echo "✅ Pulumi 版本: $(pulumi version)"
}

# ========== 检查 Ansible ==========
ensure_ansible() {
  if ! command -v ansible &> /dev/null; then
    echo "❌ 未检测到 Ansible，请手动安装："
    case "$(uname | tr '[:upper:]' '[:lower:]')" in
      linux)
        echo "👉 Ubuntu/Debian: sudo apt install ansible"
        echo "👉 RHEL/CentOS:   sudo yum install ansible"
        ;;
      darwin)
        echo "👉 macOS: brew install ansible"
        ;;
      msys*|mingw*|cygwin*)
        echo "👉 Windows 用户请参考官方安装指南：https://docs.ansible.com/"
        ;;
      *)
        echo "👉 其他平台请参考：https://docs.ansible.com/"
        ;;
    esac
    exit 1
  else
    echo "✅ Ansible 已安装: $(ansible --version | head -n 1)"
  fi
}

# ========== 检查 Terraform ==========
ensure_terraform() {
  if ! command -v terraform &> /dev/null; then
    echo "❌ 未检测到 Terraform，请手动安装："
    echo "👉 https://developer.hashicorp.com/terraform/install"
    exit 1
  fi
  echo "✅ Terraform 已安装: $(terraform version | head -n1)"
}

# ========== 环境初始化检查 ==========
init_env() {
  echo "⚙️ 初始化 Pulumi + Ansible 环境..."

  # 1️⃣ 检查 Pulumi
  ensure_pulumi

  # 2️⃣ 安装 Python 依赖
  mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF

  if [ -f "requirements.txt" ]; then
    echo "📦 安装 Python 依赖..."
    # 1. 创建虚拟环境
    python3 -m venv .venv
    # 2. 激活虚拟环境（zsh/bash）
    source .venv/bin/activate
    # 3. 安装依赖
    "$PYTHON_BIN" -m pip install -r "$PROJECT_ROOT/requirements.txt"
  fi

  # 3️⃣ 检查 Ansible
  ensure_ansible

  # 4️⃣ 检查 Terraform（可选）
  if [ -d "$TERRAFORM_DIR" ]; then
    ensure_terraform
  fi

  # 5️⃣ 初始化 Pulumi Stack
  cd "$PULUMI_DIR"
  pulumi login --local > /dev/null

  if ! pulumi stack ls | grep -q "$STACK_NAME"; then
    pulumi stack init "$STACK_NAME"
  else
    echo "✅ Stack 已存在：$STACK_NAME"
  fi

  echo "✅ 初始化完成 ✅"
}

# ========== 执行 Pulumi ==========
pulumi_run() {
  cd "$PULUMI_DIR"

  # 设置 Python 虚拟环境路径
  VENV_DIR="$PROJECT_ROOT/.venv"
  PYTHON_BIN="$VENV_DIR/bin/python"

  # 1. 激活虚拟环境
  echo "✅ 激活虚拟环境: $VENV_DIR"

  # 如果没有虚拟环境就创建并安装依赖
  if [ ! -d "$VENV_DIR" ]; then
    echo "📦 创建 Python 虚拟环境: $VENV_DIR"
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    python3 -m pip install -r requirements.txt
  else
    echo "✅ 虚拟环境已存在，直接激活"
    source "$VENV_DIR/bin/activate"
  fi

  source "$VENV_DIR/bin/activate"

  # 2. 确保 pulumi 安装在虚拟环境中
  if ! "$PYTHON_BIN" -c "import pulumi" &> /dev/null; then
    echo "⚠️ Pulumi SDK 未安装，正在安装..."
    "$PYTHON_BIN" -m pip install --upgrade pip
    "$PYTHON_BIN" -m pip install pulumi pulumi-aws PyYAML
  else
    echo "✅ Pulumi SDK 已就绪"
  fi

  # 3. 告诉 Pulumi 使用这个 Python
  export PULUMI_PYTHON_CMD="$PYTHON_BIN"

  # ✅ 明确选择 stack，若不存在则创建，避免交互式提示
  pulumi stack select "$STACK_NAME" 2>/dev/null || pulumi stack init "$STACK_NAME"

  # ✅ 自动从 config 读取 region 并设置 pulumi config（防止 provider 报错）
  if [ -f "$CONFIG_PATH/base.yaml" ]; then
    region=$(grep '^ *region:' "$CONFIG_PATH/base.yaml" | awk '{print $2}')
    if [ -n "$region" ]; then
      pulumi config set aws:region "$region" --stack "$STACK_NAME" --non-interactive
      echo "✅ Pulumi config 中设置 aws:region=$region"
    fi
  fi


  if [ ! -d "$CONFIG_PATH" ] || [ -z "$(find "$CONFIG_PATH" -maxdepth 1 -name '*.yml' -o -name '*.yaml')" ]; then
    echo "⚠️ 配置目录为空：$CONFIG_PATH，跳过部署"
    exit 0
  fi

  case "$ACTION" in
    up)
      echo "🚀 正在部署 stack: $STACK_NAME"
      pulumi up --yes
      ;;
    down)
      echo "⚠️ 先执行 destroy 确保资源干净"
      pulumi destroy --yes
      echo "🔄 执行 refresh 同步状态..."
      pulumi refresh --yes
      echo "🗑️ 正式删除 Stack..."
      pulumi stack rm "$STACK_NAME" --yes
      ;;
    export)
      echo "📤 导出 stack 状态"
      pulumi stack export --file stack-export.json
      ;;
    import)
      echo "📥 导入 stack 状态"
      pulumi stack import --file stack-export.json
      ;;
    init)
      init_env
      ;;
    *)
      print_help
      ;;
  esac
}

# ========== 执行 Ansible ==========
run_ansible() {
  if [ ! -f scripts/dynamic_inventory.py ]; then
    echo "❌ 未找到 scripts/dynamic_inventory.py"
    exit 1
  fi
  echo "🧪 执行 Ansible Playbook"
    ansible-playbook -i scripts/dynamic_inventory.py ansible/playbooks/common_setup.yml -D
    ansible-playbook -i scripts/dynamic_inventory.py ansible/playbooks/vpn-wireguard-site.yaml -D -l slave-1,master-1
    ansible-playbook -i scripts/dynamic_inventory.py ansible/playbooks/vpn-overlay.yaml -D -l slave-1,master-1
    ansible-playbook -i scripts/dynamic_inventory.py ansible/playbooks/k3s-cluster.yaml -D -l slave-1,master-1
}

# ========== 分发 ==========
case "$ACTION" in
  up|down|delete|export|import|init)
    export CONFIG_PATH
    export STACK_ENV
    pulumi_run
    ;;
  ansible)
    run_ansible
    ;;
  help|*)
    print_help
    ;;
esac
