#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

PULUMI_BIN=${PULUMI_BIN:-pulumi}
STACK_NAME=${PULUMI_STACK:-${STACK_NAME:-${STACK:-}}}
BACKEND_URL=${IAC_STATE_BACKEND:-${IAC_State_backend:-}}
BACKUPS_DIR=${PULUMI_BACKUP_DIR:-backups}

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
