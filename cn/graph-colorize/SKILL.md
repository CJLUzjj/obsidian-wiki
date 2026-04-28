---
name: graph-colorize
description: >
  通过重写 `.obsidian/graph.json` colorGroups 来对 Obsidian 图谱视图进行颜色编码。
  当用户说"给我的图谱着色"、"给 obsidian 着色"、"给图谱着色"、"按标签给图谱着色"、"按类别着色"、"在图谱中突出显示可见性"、"让图谱更加丰富多彩"、"在图谱中区分标签"，或希望 Obsidian 图谱视图中的节点按标签、文件夹或可见性着色时，使用此技能。从保险库的实际标签/类别生成 `colorGroups` 数组，并将其合并到现有 graph.json 中，不会覆盖其他图谱设置。始终先备份。
---

> 原 Skill 位置：`.skills/graph-colorize/SKILL.md`


# Graph Colorize — 对 Obsidian 图谱视图进行颜色编码

你正在重写 `$OBSIDIAN_VAULT_PATH/.obsidian/graph.json`，以便 Obsidian 的图谱视图按标签、文件夹或可见性对节点进行着色。

Obsidian 将图谱设置存储在 `<vault>/.obsidian/graph.json` 中。`colorGroups` 数组是 `{query, color}` 对的列表；每个节点的第一个匹配查询获胜。查询使用 Obsidian 的搜索语法：`tag:#foo`、`path:"concepts"`、`file:foo` 等。颜色为 `{"a": 1, "rgb": <packed-int>}`，其中整数为 `(R << 16) | (G << 8) | B`。

## 开始前

1. 读取 `~/.obsidian-wiki/config`，或回退到此仓库中的 `.env`，以获取 `OBSIDIAN_VAULT_PATH`。
2. 确认 `$OBSIDIAN_VAULT_PATH/.obsidian/` 存在。如果不存在，说明保险库从未在 Obsidian 中打开过 — 告诉用户在 Obsidian 中打开一次保险库，然后重新运行。
3. **如果 Obsidian 可能已打开，请警告用户**：Obsidian 在关闭时会覆盖 `graph.json`。告诉他们先关闭保险库，或准备好重新加载（Cmd/Ctrl+R），在重新加载前不要触及图谱设置。

## 步骤 1：选择模式

从用户的措辞推断模式。如果不明确，默认为 **by-tag**。

| 用户意图 | 模式 |
|---|---|
| "按标签着色"、"给我的图谱着色"、"让它更丰富多彩"（默认） | `by-tag` |
| "按文件夹着色"、"按类别着色"、"按目录着色" | `by-category` |
| "突出显示可见性"、"在图谱中显示内部/pii"、"可见性颜色" | `by-visibility` |
| 用户提供显式映射（`tag:#foo = red` 或 JSON blob） | `custom` |
| "结合标签和可见性" / "两者" | `combined`（可见性优先，然后是标签） |

## 步骤 2：构建 `colorGroups` 数组

### 调色板（10 种不同的色盲友好颜色）

按顺序使用。如果组数多于颜色数，循环并通过第二遍将亮度除以 ~20% 来添加亮度偏移 — 或只需限制为 10 个，并告诉用户其余标签共享"其他"颜色。

| # | Hex | rgb（打包整数） | 角色 |
|---|---|---|---|
| 0 | `#4E79A7` | `5142951` | 蓝色 |
| 1 | `#F28E2B` | `15896107` | 橙色 |
| 2 | `#E15759` | `14767961` | 红色 |
| 3 | `#76B7B2` | `7780786` | 青色 |
| 4 | `#59A14F` | `5873999` | 绿色 |
| 5 | `#EDC948` | `15583048` | 黄色 |
| 6 | `#B07AA1` | `11565217` | 紫色 |
| 7 | `#FF9DA7` | `16751527` | 粉红色 |
| 8 | `#9C755F` | `10253663` | 棕色 |
| 9 | `#BAB0AC` | `12234924` | 灰色 |

每种颜色都包装为 `{"a": 1, "rgb": <int>}`。

### 模式：`by-tag`

1. Glob `$VAULT_PATH/**/*.md`，排除 `_archives/`、`_raw/`、`.obsidian/`、`node_modules/`、`index.md`、`log.md`、`_insights.md`。
2. 从每个页面解析 frontmatter `tags`。计算每个标签的使用频率。
3. **从频率列表中删除 `visibility/*` 标签** — 它们是保留的系统标签，仅在 `by-visibility` 或 `combined` 模式中处理。
4. 按使用频率取前 10 个标签。如果少于 10 个唯一标签，使用所有标签。
5. 对于索引 `i` 处的每个标签 `T`：发出 `{"query": "tag:#T", "color": palette[i]}`。
6. 可选地，在末尾追加一个最终的全局条目用于未标记的页面：`{"query": "-[\"tag\":]", "color": palette[9]}` — 如果颜色槽 9 已被真实标签占用，则**跳过**。

### 模式：`by-category`

按此固定顺序使用七个保险库顶级文件夹，以便颜色在运行间保持稳定：

| 文件夹 | 颜色索引 |
|---|---|
| `concepts` | 0（蓝色） |
| `entities` | 1（橙色） |
| `skills` | 2（红色） |
| `references` | 3（青色） |
| `synthesis` | 4（绿色） |
| `projects` | 5（黄色） |
| `journal` | 6（紫色） |

为每个存在且至少包含一个 `.md` 文件的文件夹发出一个条目。每个条目为：

```json
{"query": "path:\"<folder>\"", "color": {"a": 1, "rgb": <int>}}
```

### 模式：`by-visibility`

按此顺序发出恰好三个条目（首先匹配获胜，因此最严格的条目优先）：

1. `visibility/pii` → `#E15759`（红色，rgb 14767961）
2. `visibility/internal` → `#F28E2B`（橙色，rgb 15896107）
3. `visibility/public` → `#59A14F`（绿色，rgb 5873999）

```json
{"query": "tag:#visibility/pii", "color": {"a": 1, "rgb": 14767961}}
```

没有 `visibility/` 标签的页面保持 Obsidian 的默认颜色 — 不添加全局条目。

### 模式：`combined`

先发出 `by-visibility` 条目，然后发出 `by-tag` 条目。可见性在冲突时获胜，因为它在列表中出现在前面。

### 模式：`custom`

如果用户给出了显式映射，按字面意思遵守。将他们给出的任何十六进制（例如 `#FF00FF`）转换为打包整数，使用 `int(hex_without_hash, 16)`。将每个包装为 `{"a": 1, "rgb": <int>}`。

## 步骤 3：合并到 graph.json（不覆盖）

1. 读取现有的 `$VAULT_PATH/.obsidian/graph.json`。如果不存在，从此最小默认值开始：
```json
{
  "collapse-filter": true,
  "search": "",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": false,
  "showOrphans": true,
  "collapse-color-groups": false,
  "colorGroups": [],
  "collapse-display": true,
  "showArrow": false,
  "textFadeMultiplier": 0,
  "nodeSizeMultiplier": 1,
  "lineSizeMultiplier": 1,
  "collapse-forces": true,
  "centerStrength": 0.518713248970312,
  "repelStrength": 10,
  "linkStrength": 1,
  "linkDistance": 250,
  "scale": 1,
  "close": true
}
```

2. **先备份**：在写入前，将现有文件复制到 `.obsidian/graph.json.backup-<YYYYMMDD-HHMM>`。如果同一分钟内已存在备份，则重用它——不要堆积重复文件。

3. **仅替换** `colorGroups` 字段为你的新数组。保持所有其他字段不变。这样可以保留用户的缩放、物理、筛选、搜索和显示偏好设置。

4. 用与原始文件相同的 JSON 风格写回文件（通常是紧凑的单行或 2 空格缩进——保留原有风格）。

## 步骤 4：报告和日志

打印摘要，如：

```
Graph colorized → .obsidian/graph.json
  Mode:    by-tag
  Groups:  7 color assignments
  Palette: blue, orange, red, teal, green, yellow, purple
  Backup:  .obsidian/graph.json.backup-20260424-1432

重新加载 Obsidian (Cmd/Ctrl+R) 以查看新颜色。
如果 Obsidian 当前打开，请先关闭它或立即重新加载——Obsidian
在关闭时会覆盖 graph.json，可能会删除这些更改。
```

追加到 `$VAULT_PATH/log.md`：

```
- [TIMESTAMP] GRAPH_COLORIZE mode=<mode> groups=<N> backup=graph.json.backup-<stamp>
```

## 边界情况

- **保险库中没有标签**（在 `by-tag` 模式下）→ 回退到 `by-category` 并告知用户。
- **用户想撤销** → 从最新的 `graph.json.backup-*` 恢复，并在 `log.md` 中记录。
- **用户想清除所有颜色组** → 设置 `colorGroups: []`，备份，记录为 `GRAPH_COLORIZE mode=clear`。
- **`.obsidian/` 缺失** → 保险库尚未在 Obsidian 中打开。告知用户打开一次，然后重新运行。不要自己创建 `.obsidian/`——Obsidian 在首次打开时会在那里填充许多文件。
- **查询语法注意事项**：包含空格的文件夹路径需要引用（`path:"my folder"`）；带嵌套斜杠的标签按字面意思工作（`tag:#visibility/internal`）；不要进行 URL 编码。
- **Obsidian 在编辑期间打开**：提示风险——Obsidian 在启动时读取 graph.json，**在关闭时重写它**。如果用户正在实时编辑，告诉他们先关闭 Obsidian 或立即运行重新加载 (Cmd/Ctrl+R)，并避免在此之前打开图形设置。

## 注意

- 这是纯配置编辑——不改变页面内容，不写入前置元数据。
- 重新运行是安全的：每次运行都会创建新备份，仅 `colorGroups` 被重写。
- 如果用户手动策划了想保留的颜色组，提供 `combined` 模式或在覆盖前询问。
- 此处的调色板与 `wiki-export` 的 `graph.html` 社区颜色相匹配，因此 Obsidian 图形和导出的可视化看起来一致。
