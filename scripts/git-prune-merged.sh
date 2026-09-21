#!/usr/bin/env bash
# 由 @22178384 贡献：删除已合并到 main 的远程分支（远端清理）。
set -euo pipefail
DEFAULT="${1:-main}"
for b in $(git branch -r --merged "$DEFAULT" | grep -vE "origin/$DEFAULT|origin/HEAD"); do
  name="${b#origin/}"
  echo "删除远程分支 $name"
  git push origin --delete "$name" || true
done
echo "远程已合并分支清理完成。"
