#!/usr/bin/env bash
# 一键同步到公开镜像仓库：脱敏导出 → 提交 → 推送
#
# 用法：
#   bash scripts/sync-public.sh              # 用默认镜像目录 ../learning-publish
#   bash scripts/sync-public.sh <镜像目录>
#
# 前置：镜像目录已经是 git 仓库且配好了 origin（首次见 scripts/publish.sh 的输出提示）。
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
MIRROR="${1:-$(dirname "$SRC")/learning-publish}"

bash "$SRC/scripts/publish.sh" "$MIRROR"

cd "$MIRROR"
[ -d .git ] || { echo "[错误] $MIRROR 还不是 git 仓库" >&2; exit 1; }

if [ -z "$(git status --porcelain)" ]; then
  echo "[跳过] 镜像内容与上次同步一致，没有需要提交的改动"
  exit 0
fi

git add -A
git commit -q -m "sync: $(date '+%Y-%m-%d %H:%M') 学习工作区更新"
echo "[推送] $(git remote get-url origin)"
git push
echo "[完成] 已同步 $(git rev-parse --short HEAD)"
