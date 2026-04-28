---
name: llm-wiki
description: >
  用于构建和维护 AI 驱动的 Obsidian wiki 的基础知识蒸馏模式。
  基于 Andrej Karpathy 的 LLM Wiki 架构。当用户想要理解 wiki 模式、设置新知识库或需要关于三层架构（原始源 →
  wiki → schema）的指导时，使用此技能。也在讨论知识管理策略、wiki 结构决策或如何组织蒸馏知识时使用。这是"理论"技能 — 其他技能处理特定操作
  （摄取、查询、linting）。
---

> 原 Skill 位置：`.skills/llm-wiki/SKILL.md`


# LLM Wiki — 知识蒸馏模式

你正在维护一个持久的、复合的知识库。wiki 不是聊天机器人 — 它是一个**编译的工件**，知识被蒸馏一次并保持最新，而不是在每次查询时重新推导。

## 三层架构

### 第 1 层：原始源（不可变）

用户的原始文档 — 文章、论文、笔记、PDF、对话日志、书签、**以及图像**（截图、白板照片、图表、幻灯片捕获）。系统永远不会修改这些。它们存放在用户保存的任何地方（通过 `.env` 中的 `OBSIDIAN_SOURCES_DIR` 配置）。图像是一等公民源：摄取技能通过 Read 工具的视觉支持读取它们，并将其解释内容视为推断内容，除非它是逐字转录的文本。图像摄取需要具有视觉能力的模型 — 不支持视觉的模型应跳过图像源并报告哪些文件被跳过。

将原始源视为"源代码" — 权威但难以直接查询。

### 第 2 层：Wiki（LLM 维护）

一组相互连接的 Obsidian 兼容 markdown 文件，按类别组织。这是编译的知识 — 综合的、交叉引用的和可导航的。每个页面都有：

- YAML frontmatter（标题、类别、标签、源、时间戳）
- Obsidian `[[wikilinks]]` 连接相关概念
- 清晰的来源 — 每个声明都可追溯到源

wiki 位于通过 `.env` 中的 `OBSIDIAN_VAULT_PATH` 配置的路径。

### 第 3 层：Schema（此技能 + 配置）

管理 wiki 结构方式的规则 — 类别、约定、页面模板和操作工作流。schema 告诉 LLM *如何*维护 wiki。

## Wiki 组织

vault 有两个结构级别：**类别**（什么类型的知识）和**项目**（知识来自哪里）。

### 类别

将页面组织到这些默认类别中（可在 `.env` 中自定义）：

| 类别 | 用途 | 示例 |
|---|---|---|
| `concepts/` | 想法、理论、心智模型 | `concepts/transformer-architecture.md` |
| `entities/` | 人物、组织、工具、项目 | `entities/andrej-karpathy.md` |
| `skills/` | 操作方法知识、程序 | `skills/fine-tuning-llms.md` |
| `references/` | 特定源的摘要 | `references/attention-is-all-you-need.md` |
| `synthesis/` | 跨源的交叉分析 | `synthesis/scaling-laws-debate.md` |
| `journal/` | 时间戳观察、会话日志 | `journal/2024-03-15.md` |

### 项目

知识通常属于特定项目。`projects/` 目录反映了这一点：

```
$OBSIDIAN_VAULT_PATH/
├── projects/
│   ├── my-project/
│   │   ├── my-project.md      ← 项目概览（以项目命名）
│   │   ├── concepts/          ← 项目范围的类别页面
│   │   ├── skills/
│   │   └── ...
│   ├── another-project/
│   │   └── ...
│   └── side-project/
│       └── ...
├── concepts/                   ← 全局（跨项目）知识
├── entities/
├── skills/
└── ...
```

**当知识是项目特定的**（仅适用于一个代码库的调试技术、项目特定的架构决策），将其放在 `projects/<project-name>/<category>/` 下。

**当知识是通用的**（如"React Server Components"这样的概念、"Andrej Karpathy"这样的人物、广泛适用的技能），将其放在全局类别目录中。

**交叉引用：** 项目页面应该 `[[wikilink]]` 到全局页面，反之亦然。项目的概览页面应链接到与该项目相关的关键概念、技能和实体页面 — 无论它们位于项目下还是全局。

**命名规则：** 项目概览文件必须命名为 `<project-name>.md`，而不是 `_project.md`。Obsidian 的图形视图使用文件名作为节点标签 — `_project.md` 使每个项目在图形中显示为 `_project`，使其不可读。所以是 `projects/my-project/my-project.md`、`projects/another-project/another-project.md` 等。

每个项目目录都有一个按如下方式结构化的概览页面：

```markdown
---
title: My Project
category: project
tags: [ai, web, backend]
source_path: ~/.claude/projects/-Users-name-Documents-projects-my-project
created: 2026-03-01T00:00:00Z
updated: 2026-04-06T00:00:00Z
---

# My Project

一段关于此项目是什么的摘要。

## 关键概念
- [[concepts/some-api]] — 用于核心功能
- [[projects/my-project/concepts/main-architecture]] — 项目特定的架构

## 相关
- [[entities/some-service]] — 部署平台
```

## 特殊文件

每个 wiki 在其根目录都有这些文件：

### `index.md`
一个按类别组织的面向内容的目录。每个条目都有一行摘要和标签。在每次摄取操作后重建此文件。格式：
```markdown
# Wiki 索引

## 概念
- [[transformer-architecture]] — 序列建模的主流架构 ( #ml #architecture)
- [[attention-mechanism]] — Transformer 的核心构建块 ( #ml #fundamentals)

## 实体
- [[andrej-karpathy]] — AI 研究员、教育工作者、前特斯拉 AI 总监 ( #person #ml)
```

**格式规则**：在开括号 `(` 和标签之间添加空格。
❌ 不要：`description (#tag)` — 破坏标签解析
✅ 正确：`description ( #tag)` — 正确的间距和标签解析

### `log.md`

按时间顺序追加的只读记录，跟踪每项操作。每个条目都可解析：

```markdown
## 日志

- [2024-03-15T10:30:00Z] INGEST source="papers/attention.pdf" pages_updated=12 pages_created=3
- [2024-03-15T11:00:00Z] QUERY query="How do transformers handle long sequences?" result_pages=4
- [2024-03-16T09:00:00Z] LINT issues_found=2 orphans=1 contradictions=1
- [2024-03-17T10:00:00Z] ARCHIVE reason="rebuild" pages=87 destination="_archives/..."
- [2024-03-17T10:05:00Z] REBUILD archived_to="_archives/..." previous_pages=87
```

### `.manifest.json`

跟踪每个已摄入的源文件 — 路径、时间戳、它生成的 wiki 页面。这是增量系统的骨干。完整架构见 `wiki-status` 技能。

清单支持：
- **增量计算** — 自上次摄入以来的新增或修改内容
- **追加模式** — 仅处理增量，而非全部内容
- **审计** — 哪个源生成了哪个 wiki 页面
- **陈旧性检测** — 源已更改但 wiki 页面未更新

## 页面模板

创建新 wiki 页面时，使用以下结构：

```markdown
---
title: 页面标题
category: concepts
tags: [ml, architecture]
aliases: [备用名称]
sources: [papers/attention.pdf]
summary: 一到两句话，≤200 字符，便于读者（或其他技能）在不打开页面的情况下预览。
provenance:
  extracted: 0.72
  inferred: 0.25
  ambiguous: 0.03
created: 2024-03-15T10:30:00Z
updated: 2024-03-15T10:30:00Z
---

# 页面标题

一段总结本页面内容的段落。

## 关键思想

- 源的核心主张，直接改述。
- 源隐含但未直接陈述的推广。 ^[inferred]
- 两个源不同意的数字。 ^[ambiguous]

使用 [[wikilinks]] 连接到相关页面。

## 开放问题

未解决或需要更多源的事项。

## 源

- [[references/attention-is-all-you-need]] — 原始论文
```

## 来源标记

Wiki 页面上的每个声明都有三种来源状态之一。内联标记它们，以便读者（和未来的摄入过程）能够区分信号和合成。

| 状态 | 标记 | 含义 |
|---|---|---|
| **已提取** | *（无标记 — 默认）* | 源实际陈述内容的改述。 |
| **推断** | `^[inferred]` 后缀 | LLM 合成的声明 — 源未直接陈述的连接、推广或含义。 |
| **模糊** | `^[ambiguous]` 后缀 | 源不同意，或源不清楚。 |

示例：

```markdown
- Transformer 在位置间并行化，不同于 RNN。
- 这就是为什么它们在现代硬件上扩展性更好。 ^[inferred]
- GPT-4 在大约 13T 个 token 上训练。 ^[ambiguous]
```

**为什么使用此语法：**
- `^[...]` 在 Obsidian 中类似脚注 — 呈现清晰，永不与 `[[wikilinks]]` 冲突。
- 内联（后缀）使单个项目符号保持单个项目符号。
- 默认 = 已提取意味着没有标记的现有页面保持有效。

**前置元数据摘要**：可选地在页面级别显示粗略混合，以便用户可以扫描推测性强的页面而无需阅读：

```yaml
provenance:
  extracted: 0.72   # 没有标记的句子/项目符号的粗略比例
  inferred: 0.25
  ambiguous: 0.03
```

这些是摄入技能在创建/更新时编写的尽力而为的数字。`wiki-lint` 重新计算它们并标记偏差。该块是可选的 — 没有它的页面按惯例被视为完全已提取。

## 检索原语

读取保管库是每个读端技能的主要成本。使用能够回答问题的最便宜的原语，**仅在更便宜的原语不足时升级**。任何需要来自保管库的内容的技能都应遵循此表，而不是直接跳到完整页面读取。

| 需求 | 原语 | 相对成本 |
|---|---|---|
| 页面是否存在？其标题/类别/标签是什么？ | 读取 `index.md`；`Grep` 前置元数据块（使用针对文件头 `^---` 块的模式限定范围） | **最便宜** |
| 页面的 1-2 句话预览 | 读取其前置元数据中的 `summary:` 字段 | **便宜** |
| 页面内的特定声明或部分 | `Grep -A <n> -B <n> "<term>" <file>` — 仅返回匹配行加上下文 | **中等** |
| 整页内容 | `Read <file>` | **昂贵** — 最后手段 |
| 跨页面的关系 | `Grep "\[\[.*?\]\]"` 遍历保管库，或从已知页面遍历 wikilinks | 具体情况 |

**规则**：仅在更便宜的原语无法回答问题时升级。如果仅从 `summary:` 字段就能回答，不要读取页面正文。如果带有 `-A 10 -B 2` 的 grepped 部分给出了声明，不要读取整个页面。打开 500 行页面来读取 15 行是浪费 485 行 token。

**为什么这很重要**：20 页保管库让你可以进行全保管库扫描。200 页保管库则不行。上述原语是技能框架在不使用数据库的情况下扩展到大型保管库的方式。
消费此表的技能：`wiki-query`、`cross-linker`、`wiki-lint`、`wiki-status`（insights 模式）。任何读取保险库的新技能都应引用本节，而不是重新发明该模式。

## 核心原则

1. **编译而非检索。** wiki 是预编译的知识。当你摄入源时，更新每个相关页面——不要只是创建源的摘要。

2. **随时间复合增长。** 每次摄入应该让 wiki 更聪明，而不仅仅是更大。将新信息合并到现有页面中，解决矛盾，加强交叉引用。

3. **来源很重要。** 每个声明都应该追溯到源。更新页面时，注明哪个源促使了更新。

4. **标记推论。** 默认句子是提取的。用 `^[inferred]` 标记合成声明，用 `^[ambiguous]` 标记有争议的声明。隐藏猜测的 wiki 会无声地腐烂；标记它的 wiki 保持可信。

5. **人类策划，LLM 维护。** 人类决定添加哪些源和提出哪些问题。LLM 处理簿记——更新交叉引用、维护一致性、记录矛盾。

6. **Obsidian 是 IDE。** 用户在 Obsidian 中浏览和探索 wiki。一切都必须是有效的 Obsidian markdown，具有工作的 wikilink。

## 环境变量

wiki 通过环境变量配置（见 `.env.example`）。唯一必需的变量是保险库路径——其他一切都有合理的默认值。

- `OBSIDIAN_VAULT_PATH` — wiki 所在位置 **（必需）**
- `OBSIDIAN_SOURCES_DIR` — 原始源文档所在位置
- `OBSIDIAN_CATEGORIES` — 逗号分隔的类别列表
- `CLAUDE_HISTORY_PATH` — Claude 对话数据所在位置

不需要 API 密钥——运行这些技能的代理已经内置了 LLM 访问权限。

## 操作模式

wiki 支持三种摄入模式：

| 模式 | 何时使用 | 发生的情况 |
|---|---|---|
| **追加** | 小增量、增量更新 | 通过清单计算增量，仅摄入新的/修改的源 |
| **重建** | 主要偏差、需要重新开始 | 将当前 wiki 存档到 `_archives/`、清空、重新处理所有源 |
| **恢复** | 需要回到之前 | 恢复之前的存档 |

使用 `wiki-status` 查看增量并获得建议。使用 `wiki-rebuild` 进行存档/重建/恢复操作。

## 参考

有关特定操作的详细信息，请参阅配套技能：
- **wiki-status** — 审计已摄入的内容、计算增量、推荐追加与重建
- **wiki-rebuild** — 存档当前 wiki、从头重建或从存档恢复
- **wiki-ingest** — 将源文档提炼为 wiki 页面
- **claude-history-ingest** — 摄入 Claude 对话历史
- **codex-history-ingest** — 摄入 Codex CLI 会话历史
- **data-ingest** — 摄入任何原始文本数据
- **wiki-query** — 针对 wiki 回答问题
- **wiki-lint** — 审计和维护 wiki 健康
- **wiki-setup** — 初始化新保险库
