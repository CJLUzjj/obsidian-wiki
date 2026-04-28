---
name: wiki-lint
description: >
  审核并维护 Obsidian wiki 的健康状况。当用户想要检查他们的信息时使用此技能
  维基问题，查找孤立页面，检测矛盾，识别过时内容，修复损坏的维基链接，
  或对其知识库进行一般维护。也会触发“清理维基”，
  “需要修复什么”、“审核我的笔记”或“维基健康检查”。
---

> 原 Skill 位置：`.skills/wiki-lint/SKILL.md`


# Wiki Lint — 健康审计

您正在黑曜石维基上执行健康检查。您的目标是发现并修复随着时间的推移而降低 wiki 价值的结构性问题。

**扫描任何内容之前：**遵循`llm-wiki/SKILL.md`中的检索基元表。与整页读取相比，更喜欢 frontmatter 范围的 grep 和部分锚定读取。在一个大的金库中，盲目地阅读每一页来检查代码正是这个框架的目的是要避免的。

## 开始之前

1.读取`.env`得到`OBSIDIAN_VAULT_PATH`
2.阅读`index.md`获取整页库存
3.阅读`log.md`了解最近的活动背景

## 棉绒检查

按顺序运行这些检查。随时报告调查结果。

### 1. 孤立页面

查找传入 wiki 链接为零的页面。这些是没有任何联系的知识孤岛。

**如何检查：**
- 全局显示库中的所有`.md`文件
- 对于每一页，Grep Vault 的其余部分以查找 `[[page-name]]` 引用
- 零传入链接的页面（`index.md` 和 `log.md` 除外）是孤立的

**如何修复：**
- 确定哪些现有页面应链接到孤立页面
- 在适当的部分添加维基链接

### 2. 损坏的维基链接

查找`[[wikilinks]]` 指向不存在的页面。

**如何检查：**
- 在所有页面上查找`\[\[.*?\]\]`
- 提取链接目标
- 检查相应的`.md`文件是否存在

**如何修复：**
- 如果目标已重命名，请更新链接
- 如果目标存在，则创建它
- 如果链接有误，请删除或更正

### 3. 缺少 Frontmatter

每个页面都应该有：标题、类别、标签、来源、创建、更新。

**如何检查：**
- Grep frontmatter 块（范围为文件头的 `^---`），而不是完整读取每一页
- 标记页面缺少必填字段

**如何修复：**
- 添加具有合理默认值的缺失字段

### 3a。缺少摘要（软警告）

每个页面*应该*有一个`summary:` frontmatter 字段——1-2 个句子，≤200 个字符。这就是廉价检索（例如 `wiki-query` 的仅索引模式）读取的内容，以避免打开页面主体。

**如何检查：**
- Grep frontmatter for `^summary:` across theVault
- 标记没有它的页面，**但作为软警告，而不是错误** - 早于该字段的旧页面没问题；该检查的存在是为了推动摄取技能在新的写入中填充它。
- 还标记摘要超过 200 个字符的页面。

**如何修复：**
- 重新摄取页面，或手动编写简短摘要（页面内容的 1-2 句话）。

### 4. 过时的内容

`updated` 时间戳相对于其来源较旧的页面。

**如何检查：**
- 将页面 `updated` 时间戳与源文件修改时间进行比较
- 标记上次更新页面后源已被修改的页面

### 5.矛盾

跨页面冲突的声明。

**如何检查：**
- 这需要阅读相关页面并比较声明
- 重点关注共享标签或大量交叉引用的页面
- 寻找诸如“然而”、“相反”、“尽管”之类的短语，它们可能表明存在的已承认的矛盾与未承认的矛盾

**如何修复：**
- 添加“开放问题”部分，指出矛盾
- 参考来源及其声明

### 6. 索引一致性

验证 `index.md` 与实际页面库存匹配。

**如何检查：**
- 将 `index.md` 中列出的页面与磁盘上的实际文件进行比较
- 检查`index.md`中的摘要是否仍然匹配页面内容

### 7. 来源漂移

检查页面是否诚实地了解其内容的多少是推断的还是提取的。有关约定，请参阅 `llm-wiki` 中的出处标记部分。**如何检查：**
- 对于带有 `provenance:` 块或任何 `^[inferred]`/`^[ambiguous]` 标记的每个页面，计算句子/项目符号以及以每个标记结尾的数量
- 计算粗略分数（`extracted`、`inferred`、`ambiguous`）
- 应用这些阈值：
  - **模糊> 15%**：标记为“投机严重”——即使七分之一的声明确实不确定，也表明该页面需要更严格的采购或应移至`synthesis/`
  - **推断 > 40%，frontmatter 中没有 `sources:`**：标记为“无源综合”——该页面正在建立连接，但没有任何可引用的内容
  - **中心页面**（按传入维基链接计数排名前 10 名），INFERRED > 20%：标记为“来源可疑的高流量页面”——中心页面上的错误会传播到链接到它们的每个页面
  - **漂移**：如果页面有 `provenance:` frontmatter 块，则当任何字段与重新计算值相差超过 0.20 时对其进行标记
- **跳过**没有 `provenance:` frontmatter 和没有标记的页面 - 按惯例视为完全提取

**如何修复：**
- 对于模糊性严重：从来源重新摄取，解决不确定的声明，或将推测性内容拆分为`synthesis/`页面
- 对于无源综合：将 `sources:` 添加到 frontmatter 或明确地将页面标记为综合
- 对于 INFERRED > 20% 的中心页面：优先考虑重新摄取 — 这里的错误具有最广泛的传播半径
- 对于漂移：更新`provenance:` frontmatter以匹配重新计算的值

### 8. 碎片标签簇

检查共享标签的页面是否确实相互链接。标签意味着一个主题簇；如果这些页面不互相引用，那么集群就会支离破碎——知识孤岛应该编织在一起。

**如何检查：**
- 对于出现在 ≥ 5 页上的每个标签：
  - `n` = 带有此标签的页数
  - `actual_links` = 此标签组中任意两个页面之间的 wiki 链接计数（检查两个方向）
  -`cohesion = actual_links / (n × (n−1) / 2)`
- 标记内聚度 < 0.15 且 n ≥ 5 的任何标签组

**如何修复：**
- 针对碎片标签运行 `cross-linker` 技能 — 它将显示并插入缺失的链接
- 如果标签组很大（n > 15）并且仍然碎片化，请考虑将其拆分为更具体的子标签

### 9. 可见性标签一致性

检查 `visibility/` 标签是否正确应用，并且没有在重要的地方悄悄丢失。

**如何检查：**

- **未标记的 PII 模式：** Grep 页面正文，用于通常指示敏感数据的模式 — 包含 `password`、`api_key`、`secret`、`token`、`ssn`、`email:`、`phone:` 的行，后跟实际值（不是字段描述）。如果页面匹配但缺少 `visibility/pii` 或 `visibility/internal`，则将其标记为可能的错误分类。
- **`visibility/pii` 没有 `sources:`：** 标记为 `visibility/pii` 的页面应始终具有 `sources:` frontmatter 字段 - 如果没有出处，则无法验证分类。标记任何`visibility/pii` 页面缺少`sources:`。
- **分类中的可见性标签：** `visibility/` 标签是系统标签，不得**出现在 `_meta/taxonomy.md` 中。如果在那里找到，请将其标记为配置错误 - 它们将被计入包含它们的页面的 5 个标签限制。

**如何修复：**
- 对于未标记的 PII 模式：将 `visibility/pii`（或 `visibility/internal`，如果是团队上下文而不是个人数据）添加到页面的 frontmatter 标记
- 对于缺少`sources:`：添加出处或升级给用户 - 不要自动填充
- 对于分类污染：从`_meta/taxonomy.md`中删除`visibility/`条目

### 10. 其他促销候选人

在`misc/`中查找已经积累了足够的项目亲和力以进行推广的页面。

**如何检查：**
- 全局`$OBSIDIAN_VAULT_PATH/misc/*.md`
- 对于每一页，阅读 `affinity` frontmatter 字段
- 标记任何单个项目得分≥3的页面

**如何修复：**
- 如果亲和力分数看起来过时，请首先运行`cross-linker`技能（例如，在具有许多wiki链接的页面上`affinity: {}`）
- 推广：将页面移动到`projects/<project-name>/references/`（或其他适当的类别），更新其`category` frontmatter，删除`promotion_status`，并grep库中的反向链接以更新它们

### 11.综合差距确定 wiki 所缺少的高价值综合机会——在许多页面中同时出现但没有 `synthesis/` 页面连接它们的概念对。

**如何检查：**
- 列出 `synthesis/` 中的所有页面 — 收集每个页面已经涵盖的概念对（来自其 `[[wikilinks]]` 或标题）
- 从`concepts/`和`entities/`中挑选10-15个经常链接的概念
- 对于每一对，运行快速 grep 来计算链接到两者的页面：
  ````bash
  grep -rl "\[\[ConceptA\]\]" "$OBSIDIAN_VAULT_PATH" --include="*.md" > /tmp/a.txt
  grep -rl "\[\[ConceptB\]\]" "$OBSIDIAN_VAULT_PATH" --include="*.md" > /tmp/b.txt
  comm -12 <(排序/tmp/a.txt) <(排序/tmp/b.txt) |厕所-l
  ````
- 标记没有现有综合页面的同现 ≥ 3 对

**如何修复：**
- 运行`/wiki-synthesize`自动发现并填补顶部空白

## 输出格式

以结构化列表的形式报告调查结果：```markdown
## Wiki Health Report

### Orphaned Pages (N found)
- `concepts/foo.md` — no incoming links

### Broken Wikilinks (N found)
- `entities/bar.md:15` — links to [[nonexistent-page]]

### Missing Frontmatter (N found)
- `skills/baz.md` — missing: tags, sources

### Stale Content (N found)
- `references/paper-x.md` — source modified 2024-03-10, page last updated 2024-01-05

### Contradictions (N found)
- `concepts/scaling.md` claims "X" but `synthesis/efficiency.md` claims "not X"

### Index Issues (N found)
- `concepts/new-page.md` exists on disk but not in index.md

### Missing Summary (N found — soft)
- `concepts/foo.md` — no `summary:` field
- `entities/bar.md` — summary exceeds 200 chars

### Provenance Issues (N found)
- `concepts/scaling.md` — AMBIGUOUS > 15%: 22% of claims are ambiguous (re-source or move to synthesis/)
- `entities/some-tool.md` — drift: frontmatter says inferred=0.10, recomputed=0.45
- `concepts/transformers.md` — hub page (31 incoming links) with INFERRED=28%: errors here propagate widely
- `synthesis/speculation.md` — unsourced synthesis: no `sources:` field, 55% inferred

### Fragmented Tag Clusters (N found)
- **#systems** — 7 pages, cohesion=0.06 ⚠️ — run cross-linker on this tag
- **#databases** — 5 pages, cohesion=0.10 ⚠️

### Visibility Issues (N found)
- `entities/user-records.md` — contains `email:` value pattern but no `visibility/pii` tag
- `concepts/auth-flow.md` — tagged `visibility/pii` but missing `sources:` frontmatter
- `_meta/taxonomy.md` — contains `visibility/internal` entry (system tag must not be in taxonomy)

### Misc Promotion Candidates (N found)
Pages in misc/ that have ≥ 3 connections to a single project and are ready to be promoted:

| Page | Top Project | Affinity Score |
|---|---|---|
| `misc/web-martinfowler-articles-microservices.md` | `obsidian-wiki` | 4 |

### Synthesis Gaps (N found)
Concept pairs that co-occur frequently but have no synthesis page:

| Pair | Co-occurrence | Suggested Action |
|---|---|---|
| [[Caching]] × [[Consistency]] | 5 pages | Run `/wiki-synthesize` |
| [[Testing]] × [[Observability]] | 3 pages | Run `/wiki-synthesize` |
```
## 代码检查后

附加到`log.md`：```
- [TIMESTAMP] LINT issues_found=N orphans=X broken_links=Y stale=Z contradictions=W prov_issues=P missing_summary=S fragmented_clusters=F visibility_issues=V promotion_candidates=C synthesis_gaps=G
```
主动解决问题或让用户决定解决哪个问题。
