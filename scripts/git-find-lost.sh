#!/usr/bin/env bash
# 列出 reflog 里还能找回的“丢失”提交：git-find-lost.sh
set -euo pipefail
git reflog --no-abbrev | head -20
echo "用 git checkout <sha> 可恢复对应提交"
