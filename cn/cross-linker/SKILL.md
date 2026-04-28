---
name: cross-linker
description: >
  扫描 Obsidian wiki 并自动发现页面之间缺失的交叉引用。
  当用户说"链接我的页面"、"查找缺失的链接"、"交叉引用"、
  "连接我的 wiki"、"添加 wikilinks"、"哪些页面应该被链接"，或在任何大规模摄入后使用此技能
  以确保新页面融入现有知识图谱。当用户在想要连接孤立页面的背景下提到"孤立页面"时也触发，
  或说出"我的 wiki 感觉不连贯"或"页面链接不好"之类的话。这是一个写入密集型技能——
  它实际修改页面以添加链接，不像 wiki-lint 只是报告问题。
---

> 原 Skill 位置：`.skills/cross-linker/SKILL.md`


# Cross-Linker — 自动化 Wiki 交叉引用

你正在通过查找和插入缺失的 `[[wikilinks]]` 来加强 wiki 的知识图谱，连接那些应该相互引用但目前还没有的页面。

**遵循 `llm-wiki/SKILL.md` 中的检索原语表。** 通过仅 grep frontmatter（不是完整页面）在第 1 步中构建注册表。为完整 `Read` 保留用于未链接提及检测阶段，即使在那里，也只读取其摘要/标题使其成为合理链接目标的页面。盲目的完整库读取正是此框架要避免的。

## 开始前

1. 读取 `.env` 以获取 `OBSIDIAN_VAULT_PATH`
2. 读取 `index.md` 以获取页面的完整清单及其单行描述
3. 浏览 `log.md` 以查看最近摄入的内容（将链接工作重点放在新页面上）

## 第 1 步：构建页面注册表

Glob 库中的所有 `.md` 文件（排除 `_archives/`、`.obsidian/`）。对于每个页面，提取：

- **文件名**（不含 `.md`）— 这是 wikilink 目标
- **标题** 来自 frontmatter
- **别名** 来自 frontmatter（如果有）
- **标签** 来自 frontmatter
- **类别** 来自 frontmatter 或目录推断
- **单行摘要** — 第一句或 `title` 字段

构建查找表：

```
page_name → { path, title, aliases, tags, summary }
```

这是你的"词汇表"— 此表中的每个条目都是有效的 wikilink 目标。

## 第 2 步：扫描缺失的链接

对于库中的每个页面：

1. **读取完整内容**
2. **提取现有 wikilinks** — 查找所有已存在的 `[[...]]` 引用
3. **搜索未链接的提及** — 检查页面的文本是否包含以下任何内容，但未被包装在 `[[...]]` 中：
   - 页面文件名（例如，单词"MyProject"出现但 `[[projects/my-project/my-project]]` 缺失）
   - frontmatter 中的页面标题
   - frontmatter 中的别名
   - 注册表中的实体名称、项目名称、概念名称

4. **检查语义连接** — 共享多个标签或在同一项目目录中但彼此不链接的页面

### 匹配规则

- **不区分大小写的名称匹配**（例如，"my-project"匹配页面 `MyProject`）
- **不区分变音符号的匹配** — 使用 Unicode NFKD 规范化页面名称和正文文本（将重音字符分解为基础字符 + 组合标记，去除组合标记）。这确保正文文本"Muller"匹配页面 `[[entities/müller]]` 反之亦然。
- **跳过自引用** — 页面不应链接到自己
- **跳过常见词** — 不链接"the"、"and"、通用术语。仅匹配独特的名称
- **优先使用最短的明确 wikilink 路径** — 当名称在库中唯一时使用 `[[page-name]]` 而不是 `[[full/path/to/page-name]]`
- **不在代码块或 frontmatter 内链接**
- **不重复链接** — 如果 `[[foo]]` 已经出现在页面上，不要添加另一个

## 第 3 步：评分和排名建议

并非每个可能的链接都值得添加。使用复合信号对每个候选项进行评分，然后用置信度标签标记它。

### 评分

| 信号 | 分数 | 示例 |
|---|---|---|
| **文本中的精确名称匹配** | +4 | "MyProject"出现在正文中 → 链接到 my-project.md |
| **共享标签（2 个以上）** | +2 | 两者都标记为 `#ai #agent` 但它们之间没有链接 |
| **同一项目，无链接** | +2 | 两者都在 `projects/my-project/` 下但彼此不引用 |
| **提及的实体/概念** | +2 | 页面提到"知识图谱" → 链接到 `[[concepts/knowledge-graphs]]` |
| **跨类别连接** | +2 | 源在 `concepts/`，目标在 `entities/`（或 `skills/` ↔ `synthesis/`）— 不同知识层使此链接在架构上更有价值 |
| **外围→中心连接** | +2 | 源页面总链接数 ≤ 2（外围）但目标有 ≥ 8（中心）— 将松散页面连接到承重概念 |
| **部分名称匹配** | +1 | "graph"出现但页面是 `knowledge-graphs` — 合理但模糊 |

### 置信度标签

根据分数用置信度标签标记每个候选项：

| 分数 | 标签 | 操作 |
|---|---|---|
| ≥ 6 | **EXTRACTED** | 链接实际上是确定的 — 精确提及或非常强的匹配。内联应用。 |
| 3–5 | **INFERRED** | 链接是合理的推断 — 共享上下文、跨类别、外围→中心。内联应用或作为相关部分。 |
| 1–2 | **AMBIGUOUS** | 弱或部分匹配。除非用户特别要求连接松散页面，否则跳过。 |

仅对 **EXTRACTED** 和 **INFERRED** 候选项采取行动。在交叉链接报告中包含置信度标签，以便用户可以在信任前审查 INFERRED 链接。

## 第 4 步：应用链接

对于每个缺失链接的页面：

### 4a：内联链接（首选）
在正文中找到该术语的第一次自然提及，并将其包装在维基链接中：

**之前：**
```markdown
This project uses knowledge graphs to connect entities.
```

**之后：**
```markdown
This project uses [[concepts/knowledge-graphs|knowledge graphs]] to connect entities.
```

当维基链接路径与显示文本不同时，使用 `[[path|display text]]` 格式。

### 4b: 相关部分（备选方案）

如果该术语在正文中没有自然提及，但这些页面在语义上相关（共享标签、同一项目），请在页面底部添加 `## Related` 部分：

```markdown
## Related

- [[projects/my-project/my-project]] — Also uses AI agents for research automation
- [[concepts/knowledge-graphs]] — Core technique used in this project
```

如果 `## Related` 部分已存在，请追加到其中。不要重复现有条目。

## 步骤 5：评分杂项页面亲和度

在主链接传递后，更新 `misc/` 中所有页面的亲和度分数（frontmatter 中具有 `promotion_status: misc` 的页面，或位于 `misc/` 目录下的页面）。

对于每个杂项页面：

1. **收集出站链接** — 页面正文中的所有 `[[wikilinks]]`
2. **收集入站链接** — 在库中搜索 `[[misc/<slug>]]` 和 `[[<slug>]]` 引用
3. 对于每个链接的页面（双向），检查它是否属于某个项目：
   - 位于 `projects/<project-name>/` 下
   - 在 frontmatter 中有与项目名称匹配的 `project:` 字段
4. 按项目名称分组并求和：`outgoing_links + incoming_links`
5. 更新杂项页面上的 `affinity` frontmatter 块：

```yaml
affinity:
  obsidian-wiki: 3
  another-project: 1
```

6. 如果任何项目的分数 ≥ 3：将此页面标记为**晋升候选**并记录在报告中

**效率说明：** 仅读取杂项页面的完整正文 — 其他页面只需进行 frontmatter 搜索以确定其项目成员资格。

## 步骤 6：报告

呈现摘要：

```markdown
## Cross-Link Report

### Links Added: 23 across 12 pages

| Page | Links Added | Confidence | Type |
|---|---|---|---|
| `projects/my-project/my-project.md` | 3 | EXTRACTED | 2 inline, 1 related |
| `entities/jane-doe.md` | 5 | INFERRED | 3 inline, 2 related |
| ... | | | |

### Orphan Pages Remaining: 2
- `references/foo.md` — no incoming or outgoing links found
- `concepts/bar.md` — could not find related pages

### Misc Promotion Candidates: N
Pages in misc/ that have ≥ 3 connections to a single project — ready to be promoted:

| Page | Top Project | Score |
|---|---|---|
| `misc/web-martinfowler-articles-microservices.md` | `obsidian-wiki` | 4 |

To promote: move the page to `projects/<project-name>/references/` and update all backlinks.

### Pages Skipped: 3
- `index.md`, `log.md` — special files
- `_archives/*` — archived content
```

## 步骤 7：更新日志和热缓存

追加到 `log.md`：
```
- [TIMESTAMP] CROSS_LINK pages_scanned=N links_added=M pages_modified=P orphans_remaining=Q misc_affinity_updated=R promotion_candidates=S
```

**`hot.md`** — 读取 `$OBSIDIAN_VAULT_PATH/hot.md`（如果缺失，从 `wiki-ingest` 中的模板创建）。使用一行摘要更新**最近活动**，说明链接了什么 — 例如"跨链接了 12 个页面中的 23 个提及；2 个孤立页面仍然存在。"保留最后 3 个操作。更新 `updated` 时间戳。

## 提示

- **在每次摄取后运行。** 新页面几乎总是连接不良的。这是解决方案。
- **谨慎使用内联链接。** 仅链接第一次自然提及，而不是每次出现。
- **不要触及 `_archives/` 中的页面。** 这些是冻结的快照。
- **尊重现有结构。** 如果页面在 `## Key Concepts` 部分中精心策划其链接，请添加到该部分而不是创建单独的 `## Related`。
- **实体页面是链接磁石。** 像 `jane-doe` 这样的实体应该从几乎每个项目页面链接。优先考虑这些。
