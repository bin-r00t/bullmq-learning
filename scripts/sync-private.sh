#!/usr/bin/env bash
# 把「原始、未脱敏」的学习工作区同步到 GitHub private 仓库（用于跨机器接手）
#
# 用法：bash scripts/sync-private.sh
# 前置：本目录是 git 仓库，且已配置名为 private 的远端，例如
#   git remote add private git@github.com:<你的账号>/<private-repo>.git
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SRC"

[ -d .git ] || { echo "[错误] $SRC 不是 git 仓库" >&2; exit 1; }
git remote get-url private >/dev/null 2>&1 || {
  echo "[错误] 还没有配置 private 远端。先执行：" >&2
  echo "  git remote add private git@github.com:<你的账号>/<private 仓库名>.git" >&2
  exit 1
}

git add -A
# 脱敏规则文件在 .gitignore 里，但私有仓库需要它（换机器后 publish.sh 才能正常工作）
[ -f "$SRC/.publish-redact.txt" ] && git add -f .publish-redact.txt

if git diff --cached --quiet; then
  echo "[跳过] 没有需要提交的改动"
  exit 0
fi

git commit -q -m "sync: $(date '+%Y-%m-%d %H:%M') 学习工作区更新（private 原始版）"
echo "[推送] $(git remote get-url private)"
git push private HEAD
echo "[完成] $(git rev-parse --short HEAD) → $(git remote get-url private)"
