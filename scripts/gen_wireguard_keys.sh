#!/bin/bash

# scripts/gen_wireguard_keys.sh
# 支持全量或指定 name 生成 WireGuard 密钥并加密到 keys.yaml

set -euo pipefail

VAULT_PASSWORD_FILE="$HOME/.vault_password"   # ✅ 正确展开用户目录
VPN_CONFIG="config/sit/vpn-overlay.yaml"
OUTPUT_FILE="config/sit/vpn-keys.yaml"

if [[ ! -f "$VAULT_PASSWORD_FILE" ]]; then
  echo "ERROR: 未找到 $VAULT_PASSWORD_FILE，请创建 ~/.vault_password 保存 ansible vault 密码。" >&2
  exit 1
fi

# 参数
SPECIFIC_NAME="${1:-}"   # 第一个参数，指定name（可选）

# 读取 hubs 和 sites 的 name
names=($(yq '.hubs[].name' "$VPN_CONFIG") $(yq '.sites[].name' "$VPN_CONFIG"))

# 检查是否指定 name
if [[ -n "$SPECIFIC_NAME" ]]; then
  if ! printf "%s\n" "${names[@]}" | grep -q "^${SPECIFIC_NAME}$"; then
    echo "ERROR: 指定的 name \"$SPECIFIC_NAME\" 不在 vpn-overlay.yaml 的 hubs 或 sites 里。" >&2
    exit 1
  fi
  names=("$SPECIFIC_NAME")
  echo "🔵 只更新指定 name: $SPECIFIC_NAME"
else
  echo "🟢 全量生成所有 names: ${names[*]}"
  echo "keys:" > "$OUTPUT_FILE"  # 只有全量时才清空 output
fi

for name in "${names[@]}"; do
  echo "生成 $name 的 WireGuard 密钥对..."

  tmpdir=$(mktemp -d)

  wg genkey > "$tmpdir/privatekey"
  cat "$tmpdir/privatekey" | wg pubkey > "$tmpdir/publickey"

  private_key_encrypted=$(ansible-vault encrypt_string --vault-password-file "$VAULT_PASSWORD_FILE" --encrypt-vault-id default "$(cat "$tmpdir/privatekey")" --name "private_key")
  public_key_encrypted=$(ansible-vault encrypt_string --vault-password-file "$VAULT_PASSWORD_FILE" --encrypt-vault-id default "$(cat "$tmpdir/publickey")" --name "public_key")

  if [[ -n "$SPECIFIC_NAME" ]]; then
    # 只更新某个 name，需要保留原有 keys.yaml
    tmp_keys=$(mktemp)

    # 先去掉原本存在的同名块
    awk -v NAME="$name" '
      BEGIN { skip=0 }
      /^  - name: / {
        if ($3 == NAME) { skip=1 }
        else { skip=0 }
      }
      skip==0 { print }
    ' "$OUTPUT_FILE" > "$tmp_keys"

    # 追加新的 key 块
    {
      echo "  - name: $name"
      echo "$private_key_encrypted" | sed 's/^/    /'
      echo "$public_key_encrypted" | sed 's/^/    /'
      echo ""
    } >> "$tmp_keys"

    mv "$tmp_keys" "$OUTPUT_FILE"
  else
    # 全量生成直接写
    {
      echo "  - name: $name"
      echo "$private_key_encrypted" | sed 's/^/    /'
      echo "$public_key_encrypted" | sed 's/^/    /'
      echo ""
    } >> "$OUTPUT_FILE"
  fi

  rm -rf "$tmpdir"
done

echo "✅ 完成生成，keys 写入到 $OUTPUT_FILE"
