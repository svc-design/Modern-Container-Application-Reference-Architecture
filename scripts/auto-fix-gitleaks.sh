#!/bin/bash
set -euo pipefail

REMOTE_URL="git@github.com:svc-design/Modern-Container-Application-Reference-Architecture.git"

echo "[*] Step 1: 使用 Gitleaks 扫描泄露路径..."
LEAKED_PATHS=$(gitleaks detect -v --report-format json \
  | jq -r '.[].File // .file' \
  | sort -u)

if [ -z "$LEAKED_PATHS" ]; then
  echo "[✓] 没有泄露路径，无需清理。"
  exit 0
fi

echo "[*] Step 2: 即将清理以下敏感文件路径："
echo "$LEAKED_PATHS"
echo

# 构建参数列表
ARGS=()
while read -r path; do
  [ -n "$path" ] && ARGS+=(--path "$path")
done <<< "$LEAKED_PATHS"

echo "[*] Step 3: 使用 git filter-repo 删除历史路径..."
git filter-repo --force "${ARGS[@]}" --invert-paths

echo "[*] Step 4: 检查并配置远程仓库 origin..."
if ! git remote get-url origin &>/dev/null; then
  echo "[!] 未检测到 origin，正在添加远程仓库：$REMOTE_URL"
  git remote add origin "$REMOTE_URL"
else
  echo "[✓] 已配置 origin -> $(git remote get-url origin)"
fi

echo "[*] Step 5: 强制推送全部历史..."
git push origin --force --all
git push origin --force --tags

echo
echo "[✓] 历史清理完毕 ✅"
echo "[*] 可选：运行 gitleaks detect 再次验证无泄露"
