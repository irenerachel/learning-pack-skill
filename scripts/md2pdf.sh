#!/bin/bash
# md2pdf.sh : 把 Markdown 转成中文渲染正确、超链接可点的 PDF（learning-pack 用）
# 排版参考 ebook-maker 电子书规范：A4 / 正文 680px / 棕褐主色 + 橙强调 / 衬线标题 / 克制提示框。
# 含 Mermaid 渲染：MD 里的 ```mermaid 流程图/思维导图会先用 mmdc 渲成 SVG 再进 PDF。
# 路径：(可选 mmdc 预渲染) -> pandoc 转内联 CSS 的 standalone HTML -> headless Chrome 打印（保留 /Link 超链接）。
# 用法：bash md2pdf.sh <文件1.md> [文件2.md ...]
# 产物：每个输入旁边生成同名 .pdf
set -euo pipefail

CHROME=""
for p in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
  [ -x "$p" ] && { CHROME="$p"; break; }
done
[ -z "$CHROME" ] && { echo "未找到 Chrome/Chromium/Edge，无法打印 PDF"; exit 1; }
command -v pandoc >/dev/null 2>&1 || { echo "未装 pandoc（brew install pandoc）"; exit 1; }
[ "$#" -ge 1 ] || { echo "用法：bash md2pdf.sh <文件.md> [更多.md ...]"; exit 1; }

# 电子书风格 CSS（衬线标题用系统字体兜底，离线可用；提示框只用单条左边框，不叠加竖线）
read -r -d '' CSS <<'CSSEOF' || true
@page { size: A4; margin: 2.2cm 2cm; }
body { font-family: "Noto Sans SC","PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif;
  max-width: 680px; margin: 0 auto; line-height: 1.85; color:#2D2D2D; font-size: 15px; }
h1 { font-family:"Noto Serif SC","Songti SC","STSong",serif; color:#8B5A2B; font-weight:900;
  font-size:2rem; text-align:center; margin:0 0 .3rem; line-height:1.35; }
h2 { font-family:"Noto Serif SC","Songti SC","STSong",serif; color:#8B5A2B; font-weight:700;
  font-size:1.45rem; margin:2.4rem 0 .9rem; padding-bottom:.35rem; border-bottom:2px solid #E4D5C2; }
h3 { color:#8B5A2B; font-weight:700; font-size:1.1rem; text-align:center; margin:.2rem 0 1rem; }
p { margin:.9rem 0; }
strong { font-weight:700; }
a { color:#8B5A2B; text-decoration:underline; word-break:break-all; }
code { font-family:"JetBrains Mono",Menlo,Consolas,monospace; color:#D35400;
  background:#F5ECE0; border-radius:4px; padding:1px 5px; font-size:.9em; }
pre { background:#2D2D2D; color:#f3f3f3; border-radius:10px; padding:15px 18px;
  line-height:1.7; overflow:auto; font-size:.85em; }
pre code { color:inherit; background:none; padding:0; }
blockquote { background:#F5ECE0; border-left:4px solid #B98A5E; border-radius:0 8px 8px 0;
  margin:1.3rem 0; padding:.7rem 1.2rem; color:#444; }
blockquote p { margin:.3rem 0; }
ol,ul { padding-left:1.5rem; }
li { margin:.3rem 0; }
table { border-collapse:collapse; width:100%; font-size:.9em; margin:1.3rem 0; }
th,td { border:1px solid #E4D5C2; padding:7px 10px; text-align:left; }
th { background:#8B5A2B; color:#fff; }
hr { border:none; border-top:1px solid #ECE0D2; margin:2rem 0; }
img,svg { max-width:100%; height:auto; display:block; margin:1.5rem auto; }
CSSEOF

TMPCSS="$(mktemp -t lp_md2pdf_css).css"
printf '%s' "$CSS" > "$TMPCSS"

for SRC in "$@"; do
  [ -f "$SRC" ] || { echo "跳过（不存在）：$SRC"; continue; }
  BASE="${SRC%.md}"
  PDF="${BASE}.pdf"
  WORK="$(mktemp -d -t lp_md2pdf)"
  INPUT="$SRC"; RESPATH="$(dirname "$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")")"

  # 若含 mermaid，先用 mmdc 把 ```mermaid 块渲成 SVG，替换为图片引用
  if grep -q '```mermaid' "$SRC"; then
    if npx --no-install @mermaid-js/mermaid-cli -i "$SRC" -o "$WORK/pre.md" -b white >/dev/null 2>&1; then
      INPUT="$WORK/pre.md"; RESPATH="$WORK"
      echo "  （已用 mmdc 渲染 Mermaid 图）"
    else
      echo "  （mmdc 渲染失败，Mermaid 将以代码块形式保留）"
    fi
  fi

  HTML="$WORK/out.html"
  pandoc "$INPUT" -f gfm -t html5 --standalone --metadata title="$(basename "$BASE")" \
    --css "$TMPCSS" --resource-path="$RESPATH" --embed-resources -o "$HTML"
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$PDF" "file://$HTML" >/dev/null 2>&1 \
  || "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$PDF" "file://$HTML" >/dev/null 2>&1
  rm -rf "$WORK"
  [ -f "$PDF" ] && echo "✅ $PDF" || echo "❌ 转换失败：$SRC"
done
rm -f "$TMPCSS"
