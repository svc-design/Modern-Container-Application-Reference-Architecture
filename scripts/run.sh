#!/bin/bash
set -e

# 项目根目录（从任意位置运行都有效）
cd "$(dirname "$0")/.."

# ========== 参数解析 ==========
DEFAULT_ENV="dev"
DEFAULT_CONFIG="config"

if [[ -n "$1" && "$1" != up && "$1" != down && "$1" != delete && "$1" != export && "$1" != import && "$1" != init && "$1" != ansible && "$1" != help ]]; then
  STACK_ENV="$1"
  ACTION="${2:-up}"
else
  STACK_ENV="${STACK_ENV:-$DEFAULT_ENV}"
  ACTION="${1:-help}"
fi

STACK_NAME="${STACK_NAME:-$STACK_ENV}"
CONFIG_PATH="${CONFIG_PATH:-config/$STACK_ENV}"

# ========== 模块目录 ==========
PULUMI_DIR="iac_modules/pulumi"
TERRAFORM_DIR="iac_modules/terraform"
ANSIBLE_DIR="ansible"

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
  echo "  up        🚀 部署资源"
  echo "  down      🔥 销毁资源"
  echo "  delete    🗑️ 删除 stack"
  echo "  export    📤 导出 stack 状态"
  echo "  import    📥 导入 stack 状态"
  echo "  init      ⚙️ 初始化依赖"
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
  if [ -f "$PULUMI_DIR/requirements.txt" ]; then
    echo "📦 安装 Python 依赖..."
    pip3 install -r "$PULUMI_DIR/requirements.txt"
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
    echo "📂 创建 Pulumi Stack: $STACK_NAME"
    pulumi stack init "$STACK_NAME"
  else
    echo "✅ Stack 已存在：$STACK_NAME"
  fi

  echo "✅ 初始化完成 ✅"
}

# ========== 执行 Pulumi ==========
pulumi_run() {
  cd "$PULUMI_DIR"
  case "$ACTION" in
    up)
      if [ ! -d "$CONFIG_PATH" ] || [ -z "$(ls -A $CONFIG_PATH/*.yaml 2>/dev/null)" ]; then
        echo "⚠️ 配置目录为空：$CONFIG_PATH，跳过部署"
        exit 0
      fi
      echo "🚀 正在部署 stack: $STACK_NAME"
      pulumi up --yes
      ;;
    down)
      echo "🔥 正在销毁 stack: $STACK_NAME"
      pulumi destroy --yes
      ;;
    delete)
      echo "🗑️ 删除 Stack: $STACK_NAME"
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
  if [ ! -f scripts/inventory.py ]; then
    echo "❌ 未找到 scripts/inventory.py"
    exit 1
  fi
  echo "🧪 执行 Ansible Playbook"
  ansible-playbook -i scripts/inventory.py "$ANSIBLE_DIR/playbooks/setup.yml"
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
