#!/usr/bin/env bash
# 把本地学习工作区导出成「可公开」的脱敏镜像仓库。
#
# 用法：
#   bash scripts/publish.sh                 # 默认输出到同级目录 ../learning-publish
#   bash scripts/publish.sh <目标目录>
#
# 设计要点：
#   1) 只允许写入「空目录」或「本脚本生成过的镜像目录」（含 .publish-mirror 标记），避免误删无关目录；
#   2) 敏感的替换规则放在不公开的 .publish-redact.txt（已 gitignore），脚本本身不含原文；
#   3) 导出后做「残留检查」：规则左值只要还能在镜像里命中，就直接失败退出。
#
# 注意：这里刻意不用 pipefail —— `grep` 在没有命中时返回 1，配合 pipefail 会
# 让「某条规则当前没有命中」直接中断整个导出，属于误伤。
set -eu

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$(dirname "$SRC")/learning-publish}"
RULES="$SRC/.publish-redact.txt"
NOTICE="$SRC/scripts/publish-notice.md"
MARKER=".publish-mirror"

[ -f "$RULES" ] || { echo "[错误] 找不到脱敏规则：$RULES" >&2; exit 1; }

mkdir -p "$DEST"
if [ -n "$(ls -A "$DEST" 2>/dev/null || true)" ] && [ ! -e "$DEST/$MARKER" ]; then
  echo "[错误] $DEST 非空且不是本脚本生成过的镜像目录，拒绝覆盖" >&2
  exit 1
fi

echo "[1/4] 同步文件 → $DEST"
rsync -a --delete \
  --exclude '.git/' \
  --exclude '.tools/' \
  --exclude 'node_modules/' \
  --exclude 'data/' \
  --exclude '*.log' \
  --exclude '*.pid' \
  --exclude '.publish-redact.txt' \
  --exclude "$MARKER" \
  "$SRC/" "$DEST/"
touch "$DEST/$MARKER"

echo "[2/4] 应用脱敏规则"
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in '' | \#*) continue ;; esac
  pat="${line%% => *}"
  rep="${line#* => }"
  [ -n "$pat" ] || continue
  # 注意参数顺序：选项必须在 `--` 之前，否则 grep 会把 --exclude-dir 当成文件名（退出码 2）。
  rc=0
  hits="$(grep -rlF --exclude-dir=.git -e "$pat" "$DEST")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "[错误] grep 扫描失败（退出码 $rc），规则：$pat" >&2
    exit 1
  fi
  mapfile -t hit_list <<< "$hits"
  for f in "${hit_list[@]:-}"; do
    [ -n "$f" ] || continue
    PAT="$pat" REP="$rep" perl -pi -e 's/\Q$ENV{PAT}\E/$ENV{REP}/g' "$f"
  done
done < "$RULES"

echo "[3/4] 写入镜像说明"
if [ -f "$DEST/README.md" ] && [ -f "$NOTICE" ]; then
  sed -i '/<!-- mirror-notice:start -->/,/<!-- mirror-notice:end -->/d' "$DEST/README.md"
  { cat "$NOTICE"; cat "$DEST/README.md"; } > "$DEST/README.md.tmp"
  mv "$DEST/README.md.tmp" "$DEST/README.md"
fi

echo "[4/4] 残留检查"
leftover=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in '' | \#*) continue ;; esac
  pat="${line%% => *}"
  [ -n "$pat" ] || continue
  # grep 退出码：0=命中，1=未命中，>1=出错。出错不能当成「干净」。
  rc=0
  found="$(grep -rlF --exclude-dir=.git -e "$pat" "$DEST")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "[错误] 残留检查扫描失败（退出码 $rc），规则：$pat" >&2
    exit 1
  fi
  if [ "$rc" -eq 0 ]; then
    echo "[残留] 仍能命中：$pat" >&2
    echo "$found" | head -3 >&2
    leftover=1
  fi
done < "$RULES"

if [ "$leftover" -ne 0 ]; then
  echo "[失败] 镜像中仍有敏感串残留，请补充规则后重跑。" >&2
  exit 1
fi

echo "[完成] 脱敏镜像：$DEST"
echo "        推送到远端：cd \"$DEST\" && git add -A && git commit -m 'sync: 脱敏镜像' && git push"
