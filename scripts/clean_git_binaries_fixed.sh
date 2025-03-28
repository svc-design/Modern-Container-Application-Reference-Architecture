#!/bin/bash
set -e

echo "📦 自动扫描 Git 中最大的历史文件并清理..."

# 检查 git-filter-repo 是否存在
if ! command -v git-filter-repo &> /dev/null; then
  echo "❌ 请先安装 git-filter-repo（https://github.com/newren/git-filter-repo）"
  exit 1
fi

# 提取前 20 个最大文件路径（唯一化）
echo "🔍 获取 Git 历史中前 20 个大文件路径..."
LARGE_PATHS=$(git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  grep '^blob' | \
  sort -k3 -n -r | \
  head -20 | \
  awk '{print $4}' | sort | uniq)

echo "🗑️ 以下路径将被从 Git 历史中永久删除："
echo "$LARGE_PATHS"

# 确认清理
read -p "⚠️ 确定要执行清理吗？此操作将重写历史 (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "❎ 已取消"
  exit 0
fi

# 构造参数数组并执行 git-filter-repo
echo "🚨 正在清理..."
git filter-repo \
  $(echo "$LARGE_PATHS" | awk '{print "--path " $1}') \
  --invert-paths

echo "✅ 清理完成！你现在可以检查仓库大小：du -sh .git"

# 可选推送
read -p "🚀 是否强制推送更改到远程？(y/n): " pushconfirm
if [[ "$pushconfirm" == "y" || "$pushconfirm" == "Y" ]]; then
  git push origin --force --all
  git push origin --force --tags
  echo "✅ 已强推完成"
else
  echo "⚠️ 请手动执行以下命令推送："
  echo "   git push origin --force --all"
  echo "   git push origin --force --tags"
fi

