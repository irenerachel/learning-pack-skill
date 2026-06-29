# learning-pack

阿真的学习包生成器 skill。给一个想学的主题，产出一套可以照着走的学习包：

- `00-学习路径.png`：一页式学习路径思维导图
- `01-系统资料.md`：系统资料与术语速查
- `02-优质视频清单.md`：按学习阶段排列的视频清单
- `03-学习笔记.md`：电子书式学习笔记

## 安装

把本目录放到 Codex 或 Claude 的 skills 目录，例如：

```bash
cp -R learning-pack ~/.codex/skills/learning-pack
```

## 文件结构

```text
.
├── SKILL.md
├── references/
│   ├── 学习包模板.md
│   └── 派单模板.md
└── scripts/
    ├── html2png.sh
    └── md2pdf.sh
```

## 使用方式

对 Agent 说类似下面的话即可触发：

```text
帮我做一份 Prompt 工程的学习包
我想系统学 Loop Engineer
XX 怎么入门
```

默认落盘到 `~/Downloads/学习包/YYYYMMDD-[主题]/`。
