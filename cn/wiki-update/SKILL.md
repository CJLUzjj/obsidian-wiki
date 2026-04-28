---
name: wiki-update
description: >
  将当前项目的知识同步到 Obsidian wiki 中。 Use this skill from any project
  当用户说“更新维基”、“同步到维基”、“将其保存到我的维基”、“更新黑曜石”时，
  或者想要将他们一直在研究的内容提炼到他们的知识库中。这是
  跨项目技能，让您可以将知识从任何地方推送到金库。
---

> 原 Skill 位置：`.skills/wiki-update/SKILL.md`


# Wiki Update — Sync Any Project to Your Wiki

您正在将当前项目中的知识提炼到用户的 Obsidian wiki 中。此技能适用于任何项目目录，而不仅仅是 obsidian-wiki 存储库。

## 开始之前

1. Read `~/.obsidian-wiki/config` to get:
   - `OBSIDIAN_VAULT_PATH` — wiki 所在的地方
   - `OBSIDIAN_WIKI_REPO` — 黑曜石维基存储库的克隆位置（用于在需要时阅读其他技能）
2. 如果`~/.obsidian-wiki/config` 不存在，请告诉用户首先从其obsidian-wiki 存储库运行`bash setup.sh`。
3. 读取`$OBSIDIAN_VAULT_PATH/.manifest.json`来检查该项目之前是否已同步过。
4. 阅读`$OBSIDIAN_VAULT_PATH/index.md` 了解 wiki 已包含的内容。

## 第 1 步：了解项目

通过扫描当前工作目录找出这个项目是什么：

- `README.md`, docs/, any markdown files
- 源结构（框架、语言、关键抽象）
- `package.json`、`pyproject.toml`、`go.mod`、`Cargo.toml` 或任何定义项目的内容
- Git 日志（重点关注表示决策的提交消息，而不是“修复拼写错误”的内容）
- Claude 内存文件（如果存在）（`.claude/` 在项目中）

从目录名称派生一个干净的项目名称。

## 步骤 2：计算 Delta

检查该项目的`.manifest.json`：

- **First time?** Full scan.一切都是新的。
- **Synced before?** Look at `last_commit_synced`. Only consider what changed since then. Use `git log <last_commit>..HEAD --oneline` to see what's new.

如果自上次同步以来没有发生任何有意义的变化，请告诉用户并停止。

## 第 3 步：决定提取什么

这是卡帕蒂模式的核心问题：**如果您在 3 个月内以零上下文回来，您想了解该项目的哪些信息？**

值得提炼的：

- 架构决策以及做出这些决策的“原因”
- 构建时发现的模式（否则你会再次谷歌的东西）
- 项目依赖哪些工具、服务、API 以及它们如何连接在一起
- 关键抽象，它们如何联系，心智模型是什么
- 评估的权衡、选择的内容以及原因
- 在构建过程中学到的东西在阅读代码中并不明显

不值得提炼：

- 显而易见的文件列表、样板文件、配置
- 个别错误修复，没有更广泛的教训
- 依赖版本，锁定文件内容
- 实现细节代码已经说得很清楚了
- 任何人都可以从差异中读取常规更改

启发式：**如果阅读代码库可以回答问题，请不要对其进行维基百科。如果您必须通过阅读 20 个提交中的 gitblame 来重新推导推理，请对其进行 wiki。**

## 步骤 4：提炼成 Wiki 页面

### 项目特定知识

位于 `$VAULT/projects/<project-name>/` 下：```
projects/<project-name>/
├── <project-name>.md          ← project overview (named after the project, NOT _project.md)
├── concepts/                  ← project-specific ideas, architectures
├── skills/                    ← project-specific how-tos, patterns
└── references/                ← project-specific source summaries
```
概述页面 (`<project-name>.md`) 应包含：
- 项目是什么（一段）
- 关键概念及其联系方式
- 指向特定项目和全球维基页面的链接

### 全球知识

非特定于项目的事物属于全局类别：

|你发现了什么 |它去哪儿了|
|---|---|
|学到的一般概念 | `concepts/` |
|可重复使用的模式或技术| `skills/` |
|工具/服务/人| `entities/` |
|跨项目分析| `synthesis/` |

### 页面格式

每个页面都需要 YAML frontmatter：```markdown
---
title: >-
    Page Title
category: concepts
tags: [tag1, tag2]
sources: [projects/<project-name>]
summary: >-
    One or two sentences (≤200 chars) describing what this page covers.
provenance:
  extracted: 0.6
  inferred: 0.35
  ambiguous: 0.05
created: TIMESTAMP
updated: TIMESTAMP
---

Use folded scalar syntax (summary: >-) for title and summary to keep frontmatter parser-safe across punctuation (:, #, quotes) without escaping rules.
Keep the title and summary contents indented by two spaces under summary: >-.

# Page Title

- A fact the codebase or a doc actually states.
- A reason the design works this way. ^[inferred]

Use [[wikilinks]] to connect to other pages.
```
**Write a `summary:` frontmatter field** on every new/updated page (1–2 sentences, ≤200 chars), using `>-` folded style.对于项目同步，一个好的摘要可以回答“此页面告诉我关于该项目的什么信息，而我从其标题中猜不到？”该字段支持 `wiki-query` 的廉价检索。

**按照`llm-wiki`（出处标记部分）应用出处标记**。特别是对于项目同步：

- **提取** — 代码、配置或文档/提交消息中可见的任何内容：文件结构、依赖项、函数签名、文件的用途。
- **推断** — *为什么*做出决定、设计原理、权衡、“团队选择 X 因为 Y” — 除非提交消息、文档或 ADR 明确说明。
- **Ambiguous** — when the code and docs disagree, or when there's clearly an in-progress migration with two patterns living side by side.

Compute the rough fractions and write the `provenance:` block on every new/updated page.

### 更新与创建

- If a page already exists in the vault, **merge** new information into it.不要创建重复项。
- If you're adding to an existing page, update the `updated` timestamp and add the new source.
- Check `index.md` to see what's already there before creating anything new.

##第五步：交叉链接

创建/更新页面后：

- Add `[[wikilinks]]` from new pages to existing related pages
- Add `[[wikilinks]]` from existing pages back to the new ones where relevant
- Link the project overview to all project-specific pages and relevant global pages

## 步骤 6：更新跟踪

### 更新`.manifest.json`

添加或更新该项目的条目：```json
{
  "projects": {
    "<project-name>": {
      "source_cwd": "/absolute/path/to/project",
      "last_synced": "TIMESTAMP",
      "last_commit_synced": "abc123f",
      "pages_in_vault": ["projects/<project-name>/<project-name>.md", "..."]
    }
  }
}
```
### 更新`index.md`

为创建的任何新页面添加条目。

### 更新`log.md`

附加：```
- [TIMESTAMP] WIKI_UPDATE project=<project-name> pages_updated=X pages_created=Y source_cwd=/path/to/project
```
### 更新`hot.md`

读取`$OBSIDIAN_VAULT_PATH/hot.md`（如果缺少，则从`wiki-ingest`中的模板创建）。使用刚刚同步的内容重写 **最近活动** - 最多 3 次操作。如果该项目是持续关注的焦点，请更新**活动线程**。使用同步期间出现的最重要的架构见解或决策来更新**关键要点**。更新`updated`时间戳。

从概念上写：“同步黑曜石维基——增加了维基捕获和维基研究技能，核心新功能是自主网络研究和对话捕获。”

## 提示

- **积极进行合并。** 如果项目使用 React Server 组件，如果 `concepts/react-server-components.md` 已经存在，则不要创建新页面。更新现有项目并将该项目添加为源。
- **查阅标签分类法。** 阅读`$VAULT/_meta/taxonomy.md`（如果存在），并使用规范标签。
- **不要复制代码。** 提炼*知识*，而不是实现。 “该项目使用具有 300 毫秒延迟的去抖搜索模式”很有用。粘贴实际的去抖函数不是。
- **项目概述是锚点。** `<project-name>.md` 文件是您阅读以了解方向的内容。让它变得好起来。
