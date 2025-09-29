#!/usr/bin/env bash
set -euo pipefail

: "${SSH_PRIVATE_KEY:?SSH_PRIVATE_KEY is required}"
: "${SSH_USER:?SSH_USER is required}"
: "${TARGET_HOST:?TARGET_HOST is required}"
: "${TARGET_IP:?TARGET_IP is required}"

install -m 700 -d "${HOME}/.ssh"
printf '%s\n' "${SSH_PRIVATE_KEY}" > "${HOME}/.ssh/id_rsa"
chmod 600 "${HOME}/.ssh/id_rsa"
ssh-keyscan -H "${TARGET_HOST}" >> "${HOME}/.ssh/known_hosts" 2>/dev/null || true
ssh-keyscan -H "${TARGET_IP}" >> "${HOME}/.ssh/known_hosts" 2>/dev/null || true

cat <<EOF_INVENTORY > inventory.ini
[vhosts]
${TARGET_HOST} ansible_host=${TARGET_IP} ansible_user=${SSH_USER}
EOF_INVENTORY
