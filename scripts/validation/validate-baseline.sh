#!/usr/bin/env bash
set -euo pipefail

provider=${1:-}
config_path=${2:-}
pulumi_dir=${3:-iac_modules/pulumi}

if [[ -z "$provider" || -z "$config_path" ]]; then
  echo "Usage: $0 <provider> <config_path> [pulumi_dir]" >&2
  exit 2
fi

if [[ ! -d "$config_path" ]]; then
  echo "[${provider}] Configuration path '$config_path' does not exist" >&2
  exit 1
fi

if ! find "$config_path" -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) -mindepth 1 -print -quit >/dev/null; then
  echo "[${provider}] Expected configuration files (yaml/json) are missing in '$config_path'" >&2
  exit 1
fi

if [[ ! -d "$pulumi_dir" ]]; then
  echo "[${provider}] Pulumi directory '$pulumi_dir' does not exist" >&2
  exit 1
fi

if ! find "$pulumi_dir" -name 'Pulumi.yaml' -print -quit >/dev/null; then
  echo "[${provider}] Pulumi project definition (Pulumi.yaml) not found under '$pulumi_dir'" >&2
  exit 1
fi

if [[ -n "${DEPLOY_DRY_RUN:-}" ]]; then
  echo "[${provider}] Dry-run flag: ${DEPLOY_DRY_RUN}";
fi

echo "[${provider}] Baseline validation checks completed successfully"
