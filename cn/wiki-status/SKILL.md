---
name: wiki-status
description: >
  显示 wiki 的当前状态 — 已摄取的内容、待处理的内容以及来源之间的差异
  和维基内容。当用户询问“状态是什么”、“摄入了多少”时使用此技能，
  “还需要处理什么”、“显示增量”、“自上次摄取以来发生了什么变化”、“wiki 仪表板”、
  或者想要了解其知识库的健康状况和完整性。也可以在决定是否使用之前使用
  追加或重建。包括由“维基洞察”、“核心是什么”触发的洞察模式，
  “显示中心”、“中心页面”、“连接的内容”、“维基结构”——分析
  wiki 本身可以显示顶级中心、跨域桥和孤立相邻页面。
---

> 原 Skill 位置：`.skills/wiki-status/SKILL.md`


# Wiki 状态 — 审计与 Delta

您正在计算 wiki 的当前状态：已摄取的内容、自上次摄取以来的新增内容以及增量是什么样的。这有助于用户决定是追加（摄取增量）还是重建（存档并重新处理所有内容）。

## 开始之前

1.读取`.env`得到`OBSIDIAN_VAULT_PATH`、`OBSIDIAN_SOURCES_DIR`、`CLAUDE_HISTORY_PATH`、`CODEX_HISTORY_PATH`
2. 在保管库根读取 `.manifest.json` — 这是摄取跟踪分类账

## 清单

该清单位于`$OBSIDIAN_VAULT_PATH/.manifest.json`。它跟踪已摄取的每个源文件。如果它不存在，那么这就是一个没有被摄入任何东西的新鲜金库。```json
{
  "version": 1,
  "last_updated": "2026-04-06T10:30:00Z",
  "sources": {
    "/absolute/path/to/file.md": {
      "ingested_at": "2026-04-06T10:30:00Z",
      "size_bytes": 4523,
      "modified_at": "2026-04-05T08:00:00Z",
      "source_type": "document",
      "project": null,
      "pages_created": ["concepts/transformers.md"],
      "pages_updated": ["entities/vaswani.md"]
    },
    "~/.claude/projects/-Users-name-my-app/abc123.jsonl": {
      "ingested_at": "2026-04-06T11:00:00Z",
      "size_bytes": 128000,
      "modified_at": "2026-04-06T09:00:00Z",
      "source_type": "claude_conversation",
      "project": "my-app",
      "pages_created": ["entities/my-app.md"],
      "pages_updated": ["skills/react-debugging.md"]
    }
  },
  "projects": {
    "my-app": {
      "source_path": "~/.claude/projects/-Users-name-my-app",
      "vault_path": "projects/my-app",
      "last_ingested": "2026-04-06T11:00:00Z",
      "conversations_ingested": 5,
      "conversations_total": 8,
      "memory_files_ingested": 3
    }
  },
  "stats": {
    "total_sources_ingested": 42,
    "total_pages": 87,
    "total_projects": 6,
    "last_full_rebuild": null
  }
}
```
## 步骤 1：扫描电流源

建立一个现在可以摄取的所有内容的清单：

### 文件（来自`OBSIDIAN_SOURCES_DIR`）```
Glob each directory in OBSIDIAN_SOURCES_DIR for all text files
Record: path, size, modification time
```
### 克劳德历史（来自`CLAUDE_HISTORY_PATH`）```
Glob: ~/.claude/projects/*/          → project directories
Glob: ~/.claude/projects/*/*.jsonl   → conversation files
Glob: ~/.claude/projects/*/memory/*.md → memory files
Record: path, size, modification time, parent project
```
### 法典历史（来自`CODEX_HISTORY_PATH`）```
Glob: ~/.codex/session_index.jsonl            → session inventory index
Glob: ~/.codex/sessions/**/rollout-*.jsonl    → session rollout transcripts
Glob: ~/.codex/history.jsonl                  → optional local history log
Glob: ~/.codex/archived_sessions/**/rollout-*.jsonl → archived rollouts (if user wants archive coverage)
Record: path, size, modification time, inferred project from cwd when available
```
### 用户之前指出的任何其他来源
检查清单中标准目录之外的源路径。

## 步骤 2：计算 Delta

将当前来源与清单进行比较。对每个源文件进行分类：

|状态 |意义|需要采取行动|
|---|---|---|
| **新** |文件存在于磁盘上，而不是在清单中 |需要摄取|
| **修改** |清单中的文件，哈希值与 `content_hash` 不同 |需要重新摄取|
| **感动** |清单中的文件，mtime 较新，但哈希值未更改 |跳过 — 内容相同，无需重新摄取 |
| **不变** |清单中的文件、mtime 和 hash 均匹配 |无事可做|
| **已删除** |在清单中，但文件不再存在于磁盘上 |请注意 — wiki 页面可能已经过时 |

当清单条目没有 `content_hash`（较旧的条目）时，仅回退到 mtime 比较。

特别是对于克劳德的历史，还需要计算：
- 新项目（`~/.claude/projects/`中的目录不在清单中）
- 现有项目中的新对话
- 更新了内存文件

特别是对于法典历史，还需要计算：
-`sessions/**`下的新部署文件
- 更新了 `session_index.jsonl` 条目（会话标题/新鲜度更改）
- 仅当请求存档覆盖范围时存档推出增量

## 步骤 3：报告状态

**可见性计数（呈现报告之前）：** 在所有库 `.md` 页面中查找 `visibility/internal` 和 `visibility/pii` 标签值的 frontmatter。计数：
- `public` = 带有 `visibility/public` 标签的页面 **或** 根本没有 `visibility/` 标签
- `internal` = 带有`visibility/internal` 标签的页面
- `pii` = 带有`visibility/pii` 标签的页面

将其包含在“概述”部分中，名称为`Page visibility: N public · M internal · K pii`。如果所有页面均未标记（完全公共保管库），请跳过该行。

给出一个清晰的总结：```markdown
# Wiki Status

## Overview
- **Total wiki pages:** 87 across 6 categories
- **Page visibility:** 72 public · 11 internal · 4 pii
- **Total sources ingested:** 42
- **Projects tracked:** 6
- **Last ingest:** 2026-04-06T11:00:00Z

## Delta (what's changed since last ingest)

### New sources (never ingested): 12
| Source | Type | Size |
|---|---|---|
| ~/Documents/research/new-paper.pdf | document | 2.1 MB |
| ~/.claude/projects/-Users-.../session-xyz.jsonl | claude_conversation | 340 KB |
| ~/.codex/sessions/2026/04/12/rollout-...jsonl | codex_rollout | 220 KB |
| ... | | |

### Modified sources (need re-ingesting): 3
| Source | Last ingested | Last modified | Delta |
|---|---|---|---|
| ~/notes/architecture.md | 2026-04-01 | 2026-04-05 | 4 days newer |
| ... | | | |

### New projects (not yet in wiki): 2
- **tractorex** (3 conversations, 2 memory files)
- **papertech** (1 conversation, 0 memory files)

### Deleted sources (ingested but gone): 0

## Summary
- **Ready to ingest:** 12 new + 3 modified = 15 sources
- **Up to date:** 27 sources unchanged
- **Recommendation:** Append (delta is small relative to total)
```
## 步骤 4：建议行动

根据增量，推荐以下之一：

|情况|推荐|
|---|---|
| Delta 很小（<总数的 20%）| **追加** — 只需摄取新的/修改的源 |
| Delta 很大（> 总数的 50%） | **重建** — 归档并重新处理所有内容 |
| Many deleted sources | **首先检查** — 检查过时的页面，然后再决定 |
|第一次/空金库| **完整摄取** — 处理一切 |
|用户只想查看状态 | **不采取任何行动** — 只需报告 |

告诉用户：
- “您有 X 个新源和 Y 个修改源。我建议 [追加/重建]。”
- “想要我[摄取增量/从头开始重建/只看一个特定项目]？”

## Insights Mode

Triggered when the user asks something like "wiki insights", "what's central in my wiki", "show me the hubs", "cross-domain bridges", "what pages are most important", or "wiki structure".这种模式是“附加的”——它不会取代增量报告，而是分析 wiki 本身的“形状”。

Where the delta report tells the user what's pending, insights mode tells them what they've already built and where the interesting structure lives.通过表面*有趣的结构*来补充`wiki-lint`（发现*问题*）。

### What to compute

**首先，构建 wikilink 图表。** 遍历所有 `.md` 页面，提取每个 `[[wikilink]]`，然后构建：
- `incoming[page]` = 链接到此页面的其他页面的计数
- `outgoing[page]` = 此页面链接到的页面数
- `tags[page]` = 来自 frontmatter 的标签集
- `category[page]` = 目录前缀（概念/、实体/、技能/等）

您将在下面的所有部分中重复使用此图表。

---

1. **锚页面（顶部中心）。** 具有最多传入链接的页面 - 承载概念。
   - 按`incoming`计数对所有页面进行排名，取前10名
   - 对于每个页面，记下传入和传出计数：传入*和*高传出的页面是连接器中心（最有价值）
   - 具有高传入但零传出的页面是接收器集线器 - 标记为交叉链接器候选者

2. **桥接页面。** 连接原本断开连接的标签集群的页面 - 删除它们将会对图进行分区。这些在结构上通常比原始枢纽数量所暗示的更重要。
   - 对于每个页面 P，找到页面对 (A, B)，其中：
     - A链接到P，B从P链接（反之亦然）
     - A 和 B 彼此共享**无标签**
     - P是A的标签簇和B的标签簇之间2跳以内的唯一路径
   - 按跨簇对P桥的数量排序； show top 5
   - 每个标签：“`P` 桥 `[tag-cluster-A]` ↔ `[tag-cluster-B]`”

3. **标签簇内聚力。** 对于每个具有 ≥ 5 个页面的标签，对其内部页面的互连紧密程度进行评分：
   - `n` = 共享此标签的页面数
   - `actual_links` = 此标签组中任意两个页面之间的 wiki 链接数
   - `cohesion = actual_links / (n × (n−1) / 2)` — 实际链接与最大可能链接的比率
   - **碎片集群**（内聚度 < 0.15，n ≥ 5）：这些页面共享一个主题，但没有交织在一起。将它们作为交联剂目标表面。
   - 按内聚力显示前 5 个标签（最强集群）和后 5 个标签（最分散）

4. **令人惊讶的连接。** 不明显的跨类别 wiki 链接 — 根据它们的意外程度来评分：
   - 对每个跨越类别边界的维基链接进行评分（例如，`concepts/` → `entities/`、`skills/` → `synthesis/`）：
     - **+3** 如果链接页面或声明被标记为`^[ambiguous]`（不确定连接，值得审查）
     - **+2** 如果链接页面标记为`^[inferred]`（合成的，未直接说明）
     - **+2** 如果类别位于不同的知识层（例如，`concepts` ↔ `entities` 比 `concepts` ↔ `concepts` 更令人惊讶）
     - **+2** 如果源页面的总链接数≤2（外围），但目标页面的链接数≥8（中心）——从边缘到中心的意外到达
   - 显示得分最高的 5 个连接，并附上每个连接的简单语言原因

5. **孤立相邻建议。** 从排名前 10 的中心链接的页面，但其自己的传出链接为零。高流量区域的死胡同——主要的交联剂候选者。

6. **粗略集群。** 按主导标签对锚点页面进行分组。 （简单的标签交叉——仅用于定向。）7. **自上次运行以来的图增量。** 将当前链接图与先前 `_insights.md` 中存储的快照进行比较：
   - 读取前一个 `_insights.md` 底部的 `<!-- GRAPH_SNAPSHOT: ... -->` 行（如果存在）——它包含一个紧凑的 JSON 边缘列表
   - 计算：添加新页面、删除页面、创建新维基链接、删除维基链接
   - 标志：上次运行时被隔离但现在具有传入链接的页面（“新连接：X，Y”）
   - 标记：自上次运行以来丢失传入链接的页面（“链接目标可能已重命名：A、B”）
   - 如果不存在以前的快照，则跳过此部分

8. **建议的问题。** 此 wiki 结构具有独特的定位来回答或揭示差距的问题：
   - 来自`^[ambiguous]` 声明：“解决：`X` 和`Y` 之间的确切关系是什么？”
   - 从桥页：“探索：为什么 `P` 将 `[cluster-A]` 连接到 `[cluster-B]`？”
   - 来自零传入链接的页面：“链接：`X` 没有传入链接 - 应该引用什么？”
   - 来自碎片集群（内聚度 < 0.15）：“审核：标签`[T]` 是否应该拆分为更集中的子标签？”
   - 最多显示 7 个，优先考虑 AMBIGUOUS，然后桥接节点，然后隔离

---

### 输出

将结果写入保管库根目录下的`_insights.md`。自由覆盖——它是可再生的。最后，将紧凑的图形快照嵌入为 HTML 注释，以便下次运行可以对其进行比较。```markdown
# Wiki Insights — <TIMESTAMP>

## Anchor Pages (top 10 hubs)
| Page | Incoming | Outgoing | Note |
|---|---|---|---|
| [[concepts/transformer-architecture]] | 23 | 8 | connector hub |
| [[entities/andrej-karpathy]] | 17 | 0 | sink hub — cross-linker candidate |

## Bridge Pages (top 5)
| Page | Bridges | Cross-cluster pairs |
|---|---|---|
| [[concepts/exponential-growth]] | #ml ↔ #economics | 4 pairs |

## Tag Cluster Cohesion
### Most cohesive (well-linked)
- **#ml** — 12 pages, cohesion 0.41
### Most fragmented (cross-linker targets)
- **#systems** — 7 pages, cohesion 0.06 ⚠️ run cross-linker on this tag

## Surprising Connections (top 5)
- [[concepts/scaling-laws]] → [[entities/gordon-moore]] — score 5
  - Reason: cross-layer (concepts ↔ entities), marked ^[inferred]
- ...

## Orphan-Adjacent (dead-ends near hubs)
- [[concepts/foo]] — linked from 3 hubs, 0 outbound links

## Rough Clusters
- **#ml** — transformer-architecture, attention-mechanism, scaling-laws
- **#systems** — distributed-consensus, raft, paxos

## Graph Delta Since Last Run
- +3 new pages, +11 new wikilinks
- Newly connected: [[concepts/bar]], [[entities/baz]]
- Lost incoming links: [[references/old-paper]] (target may have been renamed)

## Questions Worth Asking
1. Resolve: What is the exact relationship between `scaling-laws` and `moore's-law`? (^[ambiguous] claim)
2. Explore: Why does `exponential-growth` bridge #ml and #economics?
3. Link: `references/foo.md` has no incoming links — what should reference it?
4. Audit: Should tag `#systems` be split? (cohesion 0.06, 7 pages)

<!-- GRAPH_SNAPSHOT: {"nodes":["concepts/foo","entities/bar"],"edges":[["concepts/foo","entities/bar"]]} -->
```
写入文件后，追加到`log.md`：```
- [TIMESTAMP] STATUS_INSIGHTS anchors=10 bridges=N cohesion_checked=T surprising=5 questions=7 delta="+N pages +M links"
```
### 何时跳过

- Vault 的页数少于 20 — 图表结构不够。告诉用户并跳过。
- 在新的 `wiki-rebuild` 之后 — 等待至少发生一次摄取。

## 注释

- 如果清单不存在，请将所有内容报告为“新”并建议完整摄取
- 此技能仅读取和报告 - 它不会修改任何内容（除了在见解模式下写入`_insights.md`，这是可再生的）
- 实际摄取工作由摄取技能完成（`wiki-ingest`、`claude-history-ingest`、`codex-history-ingest`、`data-ingest`）
- 这些技能负责在完成后更新清单
