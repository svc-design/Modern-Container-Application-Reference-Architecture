#!/usr/bin/env bash
set -euo pipefail

RAW_KUBE_CONFIG=${RAW_KUBE_CONFIG:-}
if [[ -z "${RAW_KUBE_CONFIG}" ]]; then
  echo "KUBE_CONFIG secret is not configured" >&2
  exit 1
fi

mkdir -p "${HOME}/.kube"

if printf '%s' "${RAW_KUBE_CONFIG}" | base64 -d >"${HOME}/.kube/config" 2>/dev/null; then
  true
else
  printf '%s' "${RAW_KUBE_CONFIG}" >"${HOME}/.kube/config"
fi

chmod 600 "${HOME}/.kube/config"
