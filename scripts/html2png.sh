#!/bin/bash
# html2png.sh : 把一个 HTML 文件用 headless Chrome 截成高清 PNG（learning-pack 做思维导图图片用）
# 用法：bash html2png.sh <输入.html> <输出.png> [宽] [高]
#   宽高默认 1180x1040，按思维导图画布大小传；脚本用 2 倍像素出高清图。
set -euo pipefail

CHROME=""
for p in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
  [ -x "$p" ] && { CHROME="$p"; break; }
done
[ -z "$CHROME" ] && { echo "未找到 Chrome/Chromium/Edge"; exit 1; }
[ "$#" -ge 2 ] || { echo "用法：bash html2png.sh <输入.html> <输出.png> [宽] [高]"; exit 1; }

IN="$1"; OUT="$2"; W="${3:-1180}"; H="${4:-1040}"
[ -f "$IN" ] || { echo "输入不存在：$IN"; exit 1; }
ABS="file://$(cd "$(dirname "$IN")" && pwd)/$(basename "$IN")"

"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
  --window-size="${W},${H}" --default-background-color=ffffffff \
  --screenshot="$OUT" "$ABS" >/dev/null 2>&1 \
|| "$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
  --window-size="${W},${H}" --default-background-color=ffffffff \
  --screenshot="$OUT" "$ABS" >/dev/null 2>&1
[ -f "$OUT" ] && echo "✅ $OUT" || { echo "❌ 截图失败"; exit 1; }
