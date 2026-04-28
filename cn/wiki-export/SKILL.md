---
name: wiki-export
description: >
  将 Obsidian wiki 的知识图导出为结构化格式，以便在外部工具中使用。
  当用户说“导出 wiki”、“导出图表”、“导出到 JSON”、“导出到 Gephi”时使用此技能，
  “导出到 Neo4j”、“graphml”、“可视化 wiki”、“知识图导出”，或者想要使用它们
  另一个工具中的维基数据。输出 graph.json、graph.graphml、cypher.txt (Neo4j) 和 graph.html
  （交互式浏览器可视化）到 Vault 根目录的 wiki-export/ 目录中。
---

> 原 Skill 位置：`.skills/wiki-export/SKILL.md`


# Wiki 导出 — 知识图导出

您正在将 wiki 的 wikilink 图导出为结构化格式，以便可以在外部工具（Gephi、Neo4j、自定义脚本、浏览器可视化）中使用它。

## 开始之前

1.读取`.env`得到`OBSIDIAN_VAULT_PATH`
2. 确认保管库有要导出的页面 - 如果存在的页面少于 5 个，则警告用户并停止

## 可见性过滤器（可选）

默认情况下，**所有页面都会导出**，无论可见性标签如何。这保留了现有的行为。

如果用户请求过滤导出 - 诸如 **“公共导出”**、**“面向用户的导出”**、**“排除内部”**、**“无内部页面”** 之类的短语 - 激活 **过滤模式**：

- 构建**阻止的标签集**：`{visibility/internal, visibility/pii}`
- 构建节点列表时，跳过 frontmatter 标签包含被阻止标签的任何页面
- 跳过任一端点被排除的任何边
- 注意摘要中的过滤器：`(filtered: visibility/internal, visibility/pii excluded)`

始终包含没有 `visibility/` 标记或标记为 `visibility/public` 的页面。

## 步骤 1：构建节点和边列表

全局显示 Vault 中的所有 `.md` 文件（不包括 `_archives/`、`_raw/`、`.obsidian/`、`index.md`、`log.md`、`_insights.md`）。在过滤模式下，还跳过标签包含`visibility/internal`或`visibility/pii`的页面。

对于每个页面，从 frontmatter 中提取：
- `id` — 从库根开始的相对路径，不带 `.md` 扩展名（例如 `concepts/transformers`）
- `label` — `title` 来自 frontmatter 的字段，或文件名（如果缺失）
- `category` — 目录前缀（`concepts`、`entities`、`skills`、`references`、`synthesis`、`projects` 或 `journal`）
- `tags` — 来自 frontmatter 标签字段的数组
- `summary` — frontmatter `summary` 字段（如果存在）

这是您的**节点列表**。

对于每个页面，Grep 正文 `\[\[.*?\]\]` 以提取所有 wiki 链接：
- 解析每个`[[target]]`或`[[target|display]]` - 仅使用目标部分
- 将目标解析为节点 ID（规范化：小写、空格→连字符、条形 `.md`）
- 跳过指向节点列表外部的链接（断开的链接）
- 每个解析的链接都成为一条边：`{source: page_id, target: linked_id, relation: "wikilink", confidence: "EXTRACTED"}`
- 如果链接语句以`^[inferred]`或`^[ambiguous]`结尾，则相应地覆盖`confidence`

这是您的**边缘列表**。

## 步骤 2：分配社区 ID

通过标签聚类将页面分组为社区：
- 共享相同主导标签的页面属于同一社区
- 主导标签 = 页面 frontmatter 标签数组中的第一个标签
- 没有标签的页面获得社区 ID `null`
- 社区数量从 0 开始，按大小降序排列（最大社区 = 0）

这使得 HTML 可视化和 Gephi 等工具中基于社区的着色成为可能。

## 步骤 3：写入输出文件

如果 `wiki-export/` 不存在，请在保管库根目录中创建。写入所有四个文件：

---

### 3a。 `graph.json`

NetworkX node_link 格式 — 图形工具和脚本的标准：```json
{
  "directed": false,
  "multigraph": false,
  "graph": {
    "exported_at": "<ISO timestamp>",
    "vault": "<OBSIDIAN_VAULT_PATH>",
    "total_nodes": N,
    "total_edges": M
  },
  "nodes": [
    {
      "id": "concepts/transformers",
      "label": "Transformer Architecture",
      "category": "concepts",
      "tags": ["ml", "architecture"],
      "summary": "The attention-based architecture introduced in Attention Is All You Need.",
      "community": 0
    }
  ],
  "links": [
    {
      "source": "concepts/transformers",
      "target": "entities/vaswani",
      "relation": "wikilink",
      "confidence": "EXTRACTED"
    }
  ]
}
```
---

### 3b。 `graph.graphml`

GraphML XML 格式 — 可在 Gephi、yEd 和 Cytoscape 中加载：```xml
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/graphml">
  <key id="label" for="node" attr.name="label" attr.type="string"/>
  <key id="category" for="node" attr.name="category" attr.type="string"/>
  <key id="tags" for="node" attr.name="tags" attr.type="string"/>
  <key id="community" for="node" attr.name="community" attr.type="int"/>
  <key id="relation" for="edge" attr.name="relation" attr.type="string"/>
  <key id="confidence" for="edge" attr.name="confidence" attr.type="string"/>
  <graph id="wiki" edgedefault="undirected">
    <node id="concepts/transformers">
      <data key="label">Transformer Architecture</data>
      <data key="category">concepts</data>
      <data key="tags">ml, architecture</data>
      <data key="community">0</data>
    </node>
    <edge source="concepts/transformers" target="entities/vaswani">
      <data key="relation">wikilink</data>
      <data key="confidence">EXTRACTED</data>
    </edge>
  </graph>
</graphml>
```
每页写一个`<node>`，每个维基链接写一个`<edge>`。

---

### 3c。 `cypher.txt`

Neo4j Cypher `MERGE` 语句 — 粘贴到 Neo4j 浏览器中或使用 `cypher-shell` 运行：```cypher
// Wiki knowledge graph export — <TIMESTAMP>
// Load with: cypher-shell -u neo4j -p password < cypher.txt

// Nodes
MERGE (n:Page {id: "concepts/transformers"}) SET n.label = "Transformer Architecture", n.category = "concepts", n.tags = ["ml","architecture"], n.community = 0;
MERGE (n:Page {id: "entities/vaswani"}) SET n.label = "Ashish Vaswani", n.category = "entities", n.tags = ["person","ml"], n.community = 0;

// Relationships
MATCH (a:Page {id: "concepts/transformers"}), (b:Page {id: "entities/vaswani"}) MERGE (a)-[:WIKILINK {relation: "wikilink", confidence: "EXTRACTED"}]->(b);
```
每页写入一条 `MERGE` 节点语句，然后每条边写入一条 `MATCH`/`MERGE` 关系语句。

---

### 3d。 `graph.html`

使用 vis.js CDN 的独立交互式可视化（无本地依赖项）。用户可以在任何浏览器中打开此文件 - 无需服务器。

通过以下方式构建 HTML 文件：

1. 为 vis.js 生成节点对象的 JSON 数组：```js
{id: "concepts/transformers", label: "Transformer Architecture", color: {background: "#4E79A7"}, size: <degree * 3 + 8>, title: "concepts | #ml #architecture", community: 0}
```- 按社区颜色（循环显示：`#4E79A7`、`#F28E2B`、`#E15759`、`#76B7B2`、`#59A14F`、`#EDC948`、`#B07AA1`、`#FF9DA7`、`#9C755F`、`#BAB0AC`）
- 按程度划分的大小（传入 + 传出链接计数）：`size = degree * 3 + 8`，上限为 60
- `title` = 悬停时显示的工具提示文本：类别、标签、摘要（如果有）

2. 为 vis.js 生成边缘对象的 JSON 数组：```js
{from: "concepts/transformers", to: "entities/vaswani", dashes: false, width: 1, color: {color: "#666", opacity: 0.6}}
```- `dashes: true` 用于推断边缘
- `dashes: [4,8]` 用于模糊边缘

3. 编写完整的 HTML 文件：```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Wiki Knowledge Graph</title>
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f0f1a; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; display: flex; height: 100vh; }
  #graph { flex: 1; }
  #sidebar { width: 260px; background: #1a1a2e; border-left: 1px solid #2a2a4e; padding: 14px; overflow-y: auto; font-size: 13px; }
  #sidebar h3 { color: #aaa; font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em; margin: 0 0 10px; }
  #info { margin-bottom: 16px; line-height: 1.6; color: #ccc; }
  .legend-item { display: flex; align-items: center; gap: 8px; padding: 3px 0; font-size: 12px; }
  .dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
  #stats { margin-top: 16px; color: #555; font-size: 11px; }
</style>
</head>
<body>
<div id="graph"></div>
<div id="sidebar">
  <h3>Wiki Knowledge Graph</h3>
  <div id="info">Click a node to see details.</div>
  <h3 style="margin-top:12px">Communities</h3>
  <div id="legend"><!-- populated by JS --></div>
  <div id="stats"><!-- populated by JS --></div>
</div>
<script>
const NODES_DATA = /* NODES_JSON */;
const EDGES_DATA = /* EDGES_JSON */;
const COMMUNITY_COLORS = ["#4E79A7","#F28E2B","#E15759","#76B7B2","#59A14F","#EDC948","#B07AA1","#FF9DA7","#9C755F","#BAB0AC"];

const nodes = new vis.DataSet(NODES_DATA);
const edges = new vis.DataSet(EDGES_DATA);
const network = new vis.Network(document.getElementById('graph'), {nodes, edges}, {
  physics: { solver: 'forceAtlas2Based', forceAtlas2Based: { gravitationalConstant: -60, springLength: 120 }, stabilization: { iterations: 200 } },
  interaction: { hover: true, tooltipDelay: 100 },
  nodes: { shape: 'dot', borderWidth: 1.5 },
  edges: { smooth: { type: 'continuous' }, arrows: { to: { enabled: true, scaleFactor: 0.4 } } }
});
network.once('stabilizationIterationsDone', () => network.setOptions({ physics: { enabled: false } }));

network.on('click', ({nodes: sel}) => {
  if (!sel.length) return;
  const n = NODES_DATA.find(x => x.id === sel[0]);
  if (!n) return;
  document.getElementById('info').innerHTML = `<b>${n.label}</b><br>Category: ${n.category||'—'}<br>Tags: ${n.tags||'—'}<br>${n.summary ? '<br>'+n.summary : ''}`;
});

// Build legend
const communities = {};
NODES_DATA.forEach(n => { if (n.community != null) communities[n.community] = (communities[n.community]||0)+1; });
const leg = document.getElementById('legend');
Object.entries(communities).sort((a,b)=>b[1]-a[1]).forEach(([cid, count]) => {
  const color = COMMUNITY_COLORS[cid % COMMUNITY_COLORS.length];
  leg.innerHTML += `<div class="legend-item"><div class="dot" style="background:${color}"></div>Community ${cid} (${count})</div>`;
});
document.getElementById('stats').textContent = `${NODES_DATA.length} pages · ${EDGES_DATA.length} links`;
</script>
</body>
</html>
```
将 `/* NODES_JSON */` 和 `/* EDGES_JSON */` 替换为您在步骤 1 中生成的实际 JSON 数组。

---

## 步骤 4：打印摘要```
Wiki export complete → wiki-export/
  graph.json    — N nodes, M edges (NetworkX node_link format)
  graph.graphml — N nodes, M edges (Gephi / yEd / Cytoscape)
  cypher.txt    — N MERGE nodes + M MERGE relationships (Neo4j)
  graph.html    — interactive browser visualization (open in any browser)
```
在过滤模式下，附加一行显示排除的内容：```
  (filtered: X of Y pages excluded — visibility/internal, visibility/pii)
```
## 注释

- **重新运行是安全的** - 每次运行时所有输出文件都会被覆盖
- **跳过损坏的维基链接** - 仅导出库中存在的页面的边缘
- **如果保管库受版本控制，`wiki-export/` 目录应被 gitignored** — 这些是派生工件
- **`graph.json` 是主要格式** — 其他格式均源自它。如果未来的工具本身支持图形查询，请将其指向`graph.json`
