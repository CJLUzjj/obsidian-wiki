---
name: wiki-synthesize
description: >
  系统地发现整个黑曜石维基的合成机会——成对或集群
  跨页面频繁同时出现但没有综合页面连接它们的概念。创造
  新的综合/页面得出明确的跨领域结论。当用户说“合成
  我的维基”、“寻找联系”、“哪些概念不断出现在一起”、“/wiki-synthesize”或之后
  当金库显着增长时进行大量摄入。
---

> 原 Skill 位置：`.skills/wiki-synthesize/SKILL.md`


# Wiki Synthesize — 一流的综合发现

您正在扫描 wiki，查找在许多页面中同时出现的概念，但没有专门的综合页面连接它们。您的工作是找出这些空白，并用横切综合页面填补最有价值的空白。

## 开始之前

1. 读取`~/.obsidian-wiki/config`（首选）或`.env`（后备）以获取`OBSIDIAN_VAULT_PATH`。
2. 阅读`index.md`以获取整页库存。
3. 读取`hot.md`（如果存在）——它会显示最近的活动和可能已经指向综合机会的活动线程。
4. 阅读`_meta/taxonomy.md`以了解标签词汇。

## 步骤 1：构建共现图

扫描保管库中的每个非特殊页面（跳过`index.md`、`log.md`、`hot.md`、`_insights.md`、`_meta/*`、`_archives/*`、`_raw/*`）。

对于每个页面，收集：
- 它包含的所有`[[wikilinks]]`（传出链接）
- 它的`tags` frontmatter
- 它的`category` frontmatter

构建共现矩阵：对于每对概念/实体页面（A、B），计算有多少其他页面链接到**A 和 B。这是它们的共现分数。

您无需详尽无遗 — 瞄准共现分数最高的 20-30 对。使用 Grep 有效地查找反向链接：```bash
grep -rl "\[\[ConceptA\]\]" "$OBSIDIAN_VAULT_PATH" --include="*.md"
```
针对您的最佳候选概念运行此操作并与结果集相交。

## 步骤 2：过滤掉已经合成的对

检查 `synthesis/` 目录中是否存在现有页面。对于每个现有的综合页面：
- 阅读 `sources` 的 frontmatter 或 `[[wikilinks]]` 的正文
- 将这些概念对标记为已涵盖

从候选列表中删除覆盖的对。

## 步骤 3：对候选人进行评分和排名

对于每个剩余的候选对（或 3+ 的簇），分配一个综合值分数：

|信号|积分|
|---|---|
|同现次数≥5 | +3 |
|同现数 3-4 | +2 |
|同现计数 1-2 | +1 |
|概念属于不同类别（跨域） | +2 |
|概念共享标签但位于不同的文件夹中 | +1 |
|一个或两个概念在 `_insights.md` | 中被标记为中心。 +1 |
|综合将解决已标记的矛盾| +2 |

选出前 5 名候选人。如果用户询问特定主题（“综合有关可观察性的所有内容”），请首先过滤该域的候选者。

## 步骤 4：草稿综合页面

对于每个顶级候选人，使用以下模板在 `synthesis/` 中创建一个页面：```markdown
---
title: <Concept A> × <Concept B>
category: synthesis
tags: [<shared tags>, <domain tags>]
sources: [<all pages that link to both>]
created: TIMESTAMP
updated: TIMESTAMP
summary: "Cross-cutting synthesis of how <A> and <B> interact, with implications for <domain>."
provenance:
  extracted: 0.2
  inferred: 0.7
  ambiguous: 0.1
---

# <Concept A> × <Concept B>

## The Connection

*What makes these two concepts worth synthesizing together — the non-obvious relationship that pages about each individually don't capture.*

## Where They Co-occur

*The pages and contexts where both appear. What situations bring them together.*

## Cross-cutting Insight

*The conclusion that only becomes visible when you look at both together. This is the point of the page — the thing you couldn't see from either concept page alone.*

## Tensions and Trade-offs

*Where the two concepts pull in opposite directions. Unresolved contradictions. Cases where applying one undermines the other.*

## Open Questions

*What this synthesis surfaces that the wiki doesn't yet have an answer for. Good candidates for future research.*

## Related

- [[<Concept A>]]
- [[<Concept B>]]
- [[<other related pages>]]
```
**综合页面主要是`^[inferred]`。**您正在跨源绘制连接 - 根据定义，这就是综合。在交叉结论中应用`^[inferred]`，在来源不一致的情况下应用`^[ambiguous]`。

**标题格式为`A × B`** — 这向读者表明这是一个综合页面，而不是单独关于任一概念的页面。

## 步骤 5：从源页面反向链接

对于您创建的每个综合页面，添加从其综合的两个（或更多）概念页面到该页面的链接。在概念页面中，添加到其 `## Related` 部分：```markdown
- [[Concept A × Concept B]] — synthesis
```
如果概念页面没有 `## Related` 部分，请在底部添加一个。

## 步骤 6：报告未采取的综合机会

为前 5 名创建页面后，列出输出中的下 10 个候选者 - 得分较高但您没有为其编写页面的配对。这使用户可以了解 wiki 认为值得探索的内容，而无需强制一次运行中的所有合成。

格式：```
Skipped (consider next time):
- [[Caching]] × [[Consistency]] — co-occurs in 4 pages, cross-domain
- [[Testing]] × [[Observability]] — co-occurs in 3 pages, shares tags
...
```
## 步骤 7：更新特殊文件

**`index.md`** — 为所有新综合页面添加条目。

**`log.md`** — 附加：```
- [TIMESTAMP] WIKI_SYNTHESIZE pages_scanned=N synthesis_created=M candidates_skipped=K
```
**`hot.md`** — 读取`$OBSIDIAN_VAULT_PATH/hot.md`（如果缺少，则从`wiki-ingest` 中的模板创建）。使用合成内容更新**最近活动** - 例如“综合了 5 个横切页面：缓存 × 一致性、测试 × 可观察性，……”。使用综合中出现的任何未决问题更新**活动线程**。更新`updated`时间戳。

## 质量检查表

- [ ] 每个综合页都有一个 `summary:` 字段（≤200 个字符）
- [ ] 每个综合页面都链接回其源概念
- [ ] 源概念页面链接到综合页面
- [ ] 没有综合页面只是重申源页面上已有的内容 - 它必须添加横切见解
- [ ] `index.md` 和 `log.md` 已更新
- [ ] `hot.md` 已更新

## 提示

- **仅总结其来源的综合页面是无用的。** 价值在于连接 - 两个来源页面都没有明确说明的内容。
- **不要为了综合而综合。** 如果两个概念碰巧经常一起出现而没有真正的概念联系，请跳过它们。
- **三向综合很强大，但很少见。** 仅当三个概念形成真正的相互影响的三角形时才创建它们 - 不仅仅是因为所有三个概念都出现在同一个项目页面中。
- **首先检查`_insights.md`。** wiki 状态技能可能已经在那里标记了合成候选者 - 在从头开始运行共现扫描之前从这些合成候选者开始。
