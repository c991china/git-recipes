#!/usr/bin/env bash
# 撤销最近一次提交（改动保留在工作区）：git-undo.sh
set -euo pipefail
git reset --soft HEAD~1
echo "已撤销最近一次提交，改动保留在工作区"
