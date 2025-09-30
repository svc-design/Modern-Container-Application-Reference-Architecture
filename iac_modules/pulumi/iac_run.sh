#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

PULUMI_BIN=${PULUMI_BIN:-pulumi}
STACK_NAME=${PULUMI_STACK:-${STACK_NAME:-${STACK:-}}}
BACKEND_URL=${IAC_STATE_BACKEND:-${IAC_State_backend:-}}
BACKUPS_DIR=${PULUMI_BACKUP_DIR:-backups}
CREDENTIALS_FILE=${IAC_CREDENTIALS_FILE:-${HOME}/.iac/credentials}

load_credentials_file() {
    if [[ ! -f "${CREDENTIALS_FILE}" ]]; then
        return
    fi

    if command -v stat >/dev/null 2>&1; then
        local perms
        if stat --version >/dev/null 2>&1; then
            perms=$(stat -c "%a" "${CREDENTIALS_FILE}")
        else
            perms=$(stat -f "%OLp" "${CREDENTIALS_FILE}")
        fi
        if [[ "${perms}" != "400" ]]; then
            echo "[警告] ${CREDENTIALS_FILE} 权限建议设置为 0400（当前: ${perms}）。" >&2
        fi
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "[警告] 未找到 python3，无法解析 ${CREDENTIALS_FILE}。" >&2
        return
    fi

    local exports
    if ! exports=$(python3 - "${CREDENTIALS_FILE}" <<'PY'
import os
import shlex
import sys


def to_dict(value):
    return value if isinstance(value, dict) else {}


def find_section(data, name):
    lname = name.lower()
    for key, value in to_dict(data).items():
        if str(key).lower() == lname:
            return value
    return {}


def find_value(section, *names):
    section_dict = to_dict(section)
    lower_names = {n.lower() for n in names}
    for key, value in section_dict.items():
        if str(key).lower() in lower_names:
            return value
    return None


def ensure_string(value):
    if isinstance(value, str):
        return value.strip()
    return None


def maybe_export(env_key, raw_value, exports):
    value = ensure_string(raw_value)
    if value and not os.environ.get(env_key):
        exports.append((env_key, value))


def select_backend(backends):
    if isinstance(backends, str):
        return ensure_string(backends)

    if isinstance(backends, (list, tuple)):
        candidates = [ensure_string(item) for item in backends if ensure_string(item)]
        for candidate in candidates:
            if candidate and candidate.lower().startswith("s3://"):
                return candidate
        return candidates[0] if candidates else None

    if isinstance(backends, dict):
        direct = find_value(backends, "url", "uri", "s3", "backend")
        if isinstance(direct, (str, list, tuple, dict)):
            selected = select_backend(direct)
            if selected:
                return selected

        for value in backends.values():
            selected = select_backend(value)
            if selected:
                return selected

    return None


try:
    import yaml
except ModuleNotFoundError:
    sys.stderr.write("[警告] 解析凭据文件需要 PyYAML，请运行 'pip install PyYAML'.\n")
    sys.exit(0)


path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
except FileNotFoundError:
    sys.exit(0)
except yaml.YAMLError as exc:
    sys.stderr.write(f"[警告] 无法解析凭据文件: {exc}\n")
    sys.exit(1)

exports = []

iac_state = find_section(data, "iac_state")
    backend_section = find_section(iac_state, "backend")
    maybe_export("IAC_STATE_BACKEND", select_backend(backend_section), exports)
    backend_region = find_value(backend_section, "region", "aws_region", "default_region")
    maybe_export("AWS_REGION", backend_region, exports)
    maybe_export("AWS_DEFAULT_REGION", backend_region, exports)

state_auth = find_section(iac_state, "auth")
maybe_export("AWS_ACCESS_KEY_ID", find_value(state_auth, "ak", "access_key"), exports)
maybe_export("AWS_SECRET_ACCESS_KEY", find_value(state_auth, "sk", "secret_key"), exports)

aws_section = (
    find_section(data, "aws-global")
    or find_section(data, "aws_global")
    or find_section(data, "aws")
)
maybe_export("AWS_ACCESS_KEY_ID", find_value(aws_section, "ak", "access_key", "access_key_id"), exports)
maybe_export("AWS_SECRET_ACCESS_KEY", find_value(aws_section, "sk", "secret_key", "secret_access_key"), exports)
aws_region = find_value(aws_section, "region", "aws_region", "default_region")
maybe_export("AWS_REGION", aws_region, exports)
maybe_export("AWS_DEFAULT_REGION", aws_region, exports)

alicloud_section = find_section(data, "alicloud")
maybe_export("ALICLOUD_ACCESS_KEY", find_value(alicloud_section, "ak", "access_key", "access_key_id"), exports)
maybe_export("ALICLOUD_SECRET_KEY", find_value(alicloud_section, "sk", "secret_key", "secret_access_key"), exports)

vultr_section = find_section(data, "vultr")
maybe_export("VULTR_API_KEY", find_value(vultr_section, "api_key", "apikey"), exports)

if exports:
    for key, value in exports:
        print(f"export {key}={shlex.quote(value)}")
PY
); then
        echo "[警告] 解析 ${CREDENTIALS_FILE} 失败，已跳过自动加载。" >&2
        return
    fi
    if [[ -n "${exports}" ]]; then
        eval "${exports}"
    fi
}

load_credentials_file

# Ensure region environment variables are harmonized
if [[ -z "${AWS_REGION:-}" && -n "${AWS_DEFAULT_REGION:-}" ]]; then
    export AWS_REGION="${AWS_DEFAULT_REGION}"
elif [[ -z "${AWS_DEFAULT_REGION:-}" && -n "${AWS_REGION:-}" ]]; then
    export AWS_DEFAULT_REGION="${AWS_REGION}"
fi

BACKEND_URL=${IAC_STATE_BACKEND:-${IAC_State_backend:-${BACKEND_URL:-}}}

usage() {
    cat <<'USAGE'
用法: ./iac_run.sh <命令> [参数]

可用命令:
  init                初始化 Pulumi 后端与 Stack（需要 IAC_STATE_BACKEND 和 PULUMI_STACK）
  create              创建或更新资源（pulumi up --yes --skip-preview）
  migrate             同步当前资源状态到 S3 后端（pulumi refresh --yes）
  upgrade             执行常规的基础设施更新（pulumi up --yes）
  backup              导出 Stack 状态到本地文件（默认保存到 backups/ 目录）
  restore <文件路径>  从指定备份文件恢复 Stack 状态
  destroy             销毁当前 Stack 中的所有资源

环境变量:
  PULUMI_STACK          Pulumi Stack 名称（必需）
  IAC_STATE_BACKEND     Pulumi backend 地址（必须为 s3:// 前缀）
  CONFIG_PATH           自定义配置目录，可选
  PULUMI_BACKUP_DIR     备份输出目录，默认为 ./backups

若使用 GitHub Actions 对齐流水线，请确保预先设置云厂商访问密钥与 Pulumi 访问令牌。
USAGE
}

require_backend() {
    if [[ -z "${BACKEND_URL}" ]]; then
        echo "[错误] 未设置 IAC_STATE_BACKEND（或 IAC_State_backend）环境变量，无法连接到 S3 backend." >&2
        exit 1
    fi
    if [[ "${BACKEND_URL}" != s3://* ]]; then
        echo "[错误] IAC_STATE_BACKEND 必须为 s3:// 开头的 Pulumi 后端地址." >&2
        exit 1
    fi
    if [[ -z "${AWS_REGION:-}" && -z "${AWS_DEFAULT_REGION:-}" ]]; then
        echo "[错误] 未设置 AWS_REGION 或 AWS_DEFAULT_REGION 环境变量，无法登录到 S3 backend." >&2
        echo "       请在凭据文件中添加 region 字段，或在运行脚本前导出该环境变量。" >&2
        exit 1
    fi
    if [[ -z "${AWS_REGION:-}" ]]; then
        export AWS_REGION="${AWS_DEFAULT_REGION}"
    fi
    if [[ -z "${AWS_DEFAULT_REGION:-}" ]]; then
        export AWS_DEFAULT_REGION="${AWS_REGION}"
    fi
    "${PULUMI_BIN}" login "${BACKEND_URL}" >/dev/null
}

require_stack() {
    if [[ -z "${STACK_NAME}" ]]; then
        echo "[错误] 未设置 PULUMI_STACK 环境变量." >&2
        exit 1
    fi
    if ! "${PULUMI_BIN}" stack select "${STACK_NAME}" >/dev/null 2>&1; then
        "${PULUMI_BIN}" stack init "${STACK_NAME}"
    fi
}

command_init() {
    require_backend
    require_stack
    echo "Pulumi backend 已配置: ${BACKEND_URL}"
    echo "Pulumi stack 已就绪: ${STACK_NAME}"
}

command_create() {
    require_backend
    require_stack
    "${PULUMI_BIN}" up --stack "${STACK_NAME}" --yes --skip-preview
}

command_migrate() {
    require_backend
    require_stack
    "${PULUMI_BIN}" refresh --stack "${STACK_NAME}" --yes
}

command_upgrade() {
    require_backend
    require_stack
    "${PULUMI_BIN}" up --stack "${STACK_NAME}" --yes
}

command_backup() {
    require_backend
    require_stack
    mkdir -p "${BACKUPS_DIR}"
    timestamp=$(date +"%Y%m%d%H%M%S")
    backup_file="${BACKUPS_DIR}/${STACK_NAME}-${timestamp}.json"
    "${PULUMI_BIN}" stack export --stack "${STACK_NAME}" >"${backup_file}"
    echo "Pulumi stack 已备份到 ${backup_file}"
}

command_restore() {
    require_backend
    require_stack
    local backup_file=${1:-${BACKUP_FILE:-}}
    if [[ -z "${backup_file}" ]]; then
        echo "[错误] restore 命令需要提供备份文件路径作为参数或通过 BACKUP_FILE 环境变量传入." >&2
        exit 1
    fi
    if [[ ! -f "${backup_file}" ]]; then
        echo "[错误] 找不到备份文件 ${backup_file}." >&2
        exit 1
    fi
    "${PULUMI_BIN}" stack import --stack "${STACK_NAME}" <"${backup_file}"
}

command_destroy() {
    require_backend
    require_stack
    "${PULUMI_BIN}" destroy --stack "${STACK_NAME}" --yes
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi

    local command=$1
    shift

    case "${command}" in
        init)
            command_init "$@"
            ;;
        create)
            command_create "$@"
            ;;
        migrate)
            command_migrate "$@"
            ;;
        upgrade)
            command_upgrade "$@"
            ;;
        backup)
            command_backup "$@"
            ;;
        restore)
            command_restore "$@"
            ;;
        destroy)
            command_destroy "$@"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            echo "[错误] 未知命令: ${command}" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"
