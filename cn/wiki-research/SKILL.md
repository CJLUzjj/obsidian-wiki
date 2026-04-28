---
name: wiki-research
description: >
  通过多轮网络搜索自主研究主题、综合结果和文件结构化
  结果进入黑曜石维基。当用户说“/wiki-research [topic]”时使用此技能，
  “研究 X”、“找到有关 Y 的一切”、“深入研究 Z”、“对 X 进行自主研究”、
  或者想要将某个主题的全面的、来自网络的知识直接归档到他们的 wiki 中。
---

> 原 Skill 位置：`.skills/wiki-research/SKILL.md`


# Wiki Research — 自主多轮研究

您正在针对某个主题运行一个自主研究循环，综合您所发现的内容，并将结果作为永久知识归档到黑曜石维基中。

## 开始之前

1. 读取`~/.obsidian-wiki/config`（首选）或`.env`（后备）以获取`OBSIDIAN_VAULT_PATH`
2. 阅读 `$OBSIDIAN_VAULT_PATH/index.md` 以了解 wiki 中已有的内容 — 不要重新研究 wiki 涵盖的内容
3. 读取`$OBSIDIAN_VAULT_PATH/hot.md`（如果存在）——它会显示最近的上下文
4. 检查 `$OBSIDIAN_VAULT_PATH/references/research-config.md` 是否存在 - 它可能定义源首选项、要跳过的域或此库的置信度规则

如果研究主题不明确，请与用户确认。然后继续。

## 研究配置（可选）

如果库中存在`references/research-config.md`，请读取它并应用它定义的任何规则：
- 来源偏好（例如，更喜欢学术来源，避免某些领域）
- 要跳过的域
- 信心评分调整
- 特定主题的限制

如果该文件不存在，则继续使用默认值。

## 第一轮——广泛调查

**目标：** 全面了解该主题。

1. 将主题分解为 **3-5 个不同的角度**（例如，对于“矢量数据库”：它们是什么、何时使用它们、主要实现、权衡、生产陷阱）
2. 对于每个角度，使用不同的措辞运行 **2-3 `WebSearch` 查询**
3. 对于每个角度的前 2-3 个结果，使用`WebFetch`（或`defuddle <url>`，如果可用 - 更清晰的提取）来获取内容
4. 从每个获取的页面中提取：
   - **关键主张** — 来源明确指出的内容
   - **概念** — 引入的想法、术语、框架
   - **实体** — 提到的工具、人员、组织
   - **矛盾** — 来源相互不一致的地方

随时跟踪已涵盖的内容和缺少的内容。

## 第 2 轮 — 间隙填充

**目标：** 弥补第一轮留下的漏洞。

回顾第一轮的成果：
- 消息来源提出了哪些问题但没有回答？
- 消息来源在哪里相互矛盾？
- 哪些角度的覆盖范围较薄？

运行**最多 5 次有针对性的搜索**，专门解决这些差距。与链接聚合器相比，更喜欢主要来源、官方文档和权威分析。

将发现添加到您的工作集中。更新矛盾清单。

## 第 3 轮 — 综合检查

**目标：**解决矛盾；确认深度足够。

如果主要矛盾仍未解决：
- 运行一次最终目标传递（2-3 次搜索）以找到权威的解决方案
- 如果无法解决，请在综合页面中明确标记矛盾

如果矛盾很小或者在第二轮之后感觉主题已经被很好地涵盖，则跳过额外的搜索并继续归档。

**停止条件：** 当达到深度或完成 3 轮时停止 - 不要无限期循环。

## 归档——编写 Wiki 页面

将所有发现组织到四个输出区域的 wiki 页面中：

### 1.sources/——每个主要参考文献一页

对于每个重要来源（通常总共 4-8 页）：```yaml
---
title: >-
  <Source title>
category: references
tags: [<2-4 domain tags>]
sources:
  - "<URL>"
source_url: "<URL>"
created: <ISO-8601 timestamp>
updated: <ISO-8601 timestamp>
summary: >-
  <1-2 sentences describing what this source covers, ≤200 chars>
provenance:
  extracted: 0.X
  inferred: 0.X
  ambiguous: 0.X
---
```
正文：标题、URL、涵盖内容、关键声明（带有出处标记）、限制。

### 2.concepts/ — 每个实质性概念一页

对于跨来源出现的每个重要概念：

标准概念frontmatter + body。将概念相互链接并链接到源页面。

### 3. 实体/——工具、组织、人员

对于遇到的每个重要实体（工具、图书馆、公司、主要作者）：

标准实体前沿。链接回使用实体及其出现的来源的概念。

### 4.综合/研究：[主题].md — 主综合

主要输出：对发现的所有内容进行结构化综合。```yaml
---
title: >-
  Research: <Topic>
category: synthesis
tags: [<3-5 domain tags>, research]
sources: [<list of source URLs or page paths>]
created: <ISO-8601 timestamp>
updated: <ISO-8601 timestamp>
summary: >-
  Synthesis of <N>-round research on <topic>. Covers <core findings in ≤200 chars>.
provenance:
  extracted: 0.X
  inferred: 0.X
  ambiguous: 0.X
---

# Research: <Topic>

## Overview
<2-4 sentence executive summary of what the research found>

## Key Findings
<Bulleted list of the most important claims, each with a [[source page]] citation>

## Core Concepts
<Links to concept pages created, with one-line descriptions>

## Entities & Tools
<Links to entity pages, with one-line descriptions>

## Contradictions & Open Questions
<Where sources disagree or where the research hit limits>

## Sources Consulted
<Linked list of all source pages>
```
## 交联

归档所有页面后：
- 每个概念页面应链接到至少 2 个源页面
- 每个源页面都应该链接到它所通知的概念页面
- 综合页面应链接到生成的所有概念、实体和源页面

检查 `index.md` 是否有相同主题的现有页面 - 合并到现有页面而不是创建重复项。

## 更新跟踪文件

**`.manifest.json`** — 添加 `research` 条目：```json
{
  "type": "research",
  "topic": "<topic>",
  "researched_at": "TIMESTAMP",
  "rounds_completed": 3,
  "sources_fetched": N,
  "pages_created": ["..."],
  "pages_updated": ["..."]
}
```
**`index.md`** — 在各自的部分下添加所有新页面。

**`log.md`** — 附加：```
- [TIMESTAMP] WIKI_RESEARCH topic="<topic>" rounds=N sources_fetched=N pages_created=M
```
**`hot.md`** — 用研究主题和核心发现更新**近期活动**。如果此情况正在进行，请更新**活动线程**。更新`updated`时间戳。

## 质量检查表

- [ ] 已完成 3 轮（或在足够深度停止）
- [ ] 综合页面存在于`synthesis/Research: [Topic].md`
- [ ] 为主要参考文献编写的源页面
- [ ] 为重要项目编写的概念和实体页面
- [ ] 综合页面中标记的矛盾
- [ ] 所有页面交叉链接
- [ ] `index.md`、`log.md`、`hot.md`、`.manifest.json` 已更新
