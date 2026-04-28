---
name: wiki-dashboard
description: >
  使用 Obsidian Bases（原生）创建 ObsidianVault 的动态、可查询的仪表板视图
  黑曜石功能可将金库正面内容转变为交互式表格、卡片库和列表。
  当用户说“创建仪表板”、“保管库仪表板”、“将所有 X 显示为表格”时，请使用此技能，
  “动态视图”，“查询我的库”，“构建内容索引”，“显示所有概念/实体/项目”，
  或者想要一个结构化的、自动更新的 wiki 内容视图。
  需要 Obsidian 1.8+（Bases 是核心插件，无需外部安装）。
---

> 原 Skill 位置：`.skills/wiki-dashboard/SKILL.md`


# Wiki 仪表板 — 动态 Vault 视图

您正在创建一个 `.base` 文件 - 一个 Obsidian Bases 定义，它将Vault frontmatter 转换为实时的、可查询的视图。 `.base` 格式是 Obsidian 1.8+ 的原生格式，不需要任何插件。

## 开始之前

1. 读取`~/.obsidian-wiki/config`（首选）或`.env`（后备）以获取`OBSIDIAN_VAULT_PATH`
2.阅读`$OBSIDIAN_VAULT_PATH/index.md`以了解存在哪些类别和页面
3. 如果未指定，询问用户想要查看什么内容 — 什么文件夹、标签、类别或日期范围？

## 黑曜石基地可以做什么

`.base` 文件定义库注释的数据库样式视图。每个文件声明：
- **要包含哪些注释** — 按文件夹、标签、frontmatter 属性或组合过滤
- **显示哪些属性** — 任何 frontmatter 字段都会成为一列
- **什么视图类型** — `table`、`cards` 或 `list`
- **排序和分组** — 按任何属性
- **计算列** — 使用`file.*` 帮助器和算术的公式

将 `.base` 嵌入任何带有 `![[MyBase.base]]` 的注释中。

## 第 1 步：理解请求

确定：
- **显示什么** — 类别中的所有页面？带有特定标签的页面？项目的页面？
- **哪些列重要** — 标题、标签、已创建、已更新、摘要、类别、项目？
- **视图类型** — 表格（默认）、卡片（视觉）或列表（最小）
- **排序顺序** — 按更新（默认）、创建、标题或自定义属性
- **任何过滤器** — 日期范围、特定标签、文件夹范围

## 步骤 2：生成 `.base` 文件

`.base` 格式是 YAML。以下是您将使用的模式：

### 基本表 — 类别文件夹中的所有页面```yaml
filters:
  - type: folder
    folder: concepts
columns:
  - property: file.name
    title: Page
  - property: tags
    title: Tags
  - property: summary
    title: Summary
  - property: updated
    title: Updated
sort:
  - property: updated
    direction: desc
view: table
```
### 按标签过滤```yaml
filters:
  - type: tag
    tag: "#machine-learning"
columns:
  - property: file.name
    title: Page
  - property: category
    title: Category
  - property: summary
    title: Summary
  - property: created
    title: Created
sort:
  - property: created
    direction: desc
view: table
```
### 多重过滤器（文件夹和标签）```yaml
filters:
  operator: and
  conditions:
    - type: folder
      folder: projects
    - type: tag
      tag: "#active"
columns:
  - property: file.name
    title: Project
  - property: summary
    title: Summary
  - property: updated
    title: Last Updated
view: cards
```
### 计算列（自上次更新以来的天数）```yaml
columns:
  - property: file.name
    title: Page
  - property: updated
    title: Updated
  - formula: "floor((now() - updated) / 86400000)"
    title: Days Stale
    type: number
sort:
  - formula: "floor((now() - updated) / 86400000)"
    direction: desc
view: table
```
### 可用的过滤器运算符和函数
- `file.hasTag("tag")` — 布尔值，如果页面有标签则为 true
- `file.inFolder("path")` — 布尔值，如果页面位于文件夹中则为 true
- `file.name` — 笔记的文件名（不带扩展名）
- `file.path` — 完整的保管库相对路径
- `now()` — 当前时间戳（以毫秒为单位）
- 算术：`+`、`-`、`*`、`/`、`floor()`、`ceil()`
- 比较：`==`、`!=`、`>`、`<`、`>=`、`<=`

## 第三步：写入文件

目标路径：`$OBSIDIAN_VAULT_PATH/_meta/<dashboard-name>.base`

使用源自仪表板用途的 slug：
- “所有概念” → `_meta/concepts-index.base`
-“最近摄取”→`_meta/recent-ingests.base`
- “项目概述” → `_meta/projects-overview.base`
- “陈旧页面” → `_meta/stale-pages.base`

如果`_meta/`尚不存在，则创建它。

## 步骤 4：嵌入（可选）

如果用户希望将仪表板嵌入到现有注释中（例如，`index.md` 或项目概述），请添加：```markdown
## <Dashboard Title>

![[_meta/<dashboard-name>.base]]
```
在修改现有注释之前询问用户。

## 步骤 5：更新跟踪

**`log.md`** — 附加：```
- [TIMESTAMP] WIKI_DASHBOARD name="<slug>" view=<type> filter="<description>"
```
不需要清单或索引更新 - `.base` 文件是实时查询，而不是静态内容页面。

## 常用仪表板配方

如果用户不确定要询问什么，请告诉他们这些信息：

|仪表板|它显示了什么 |
|---|---|
| **内容索引** |所有 wiki 页面均按类别分组，可按更新日期排序 |
| **实体追踪器** |带有标签和来源的所有实体页面（人员、工具、组织）|
| **摄取日志** |页面按 `created` 日期排序 — 查看最近添加的内容 |
| **过时的内容** |页面已超过 30 天未更新 — 维护视图 |
| **项目概览** |带有上次同步日期的所有项目页面 |
| **标签云** |按标签分组的页面 — 查看跨主题的报道 |
| **研究跟踪器** |所有标记为 `research` 的综合页面 — 显示研究历史 |

## 质量检查表

- [ ] `.base` YAML 有效并使用正确的字段名称
- [ ] 过滤器符合用户的意图
- [ ] 文件写入`_meta/`，带有描述性的段
- [ ] `log.md` 已更新
- [ ] 用户告知如何嵌入它 (`![[_meta/<name>.base]]`) 以及需要什么 Obsidian 版本 (1.8+)
