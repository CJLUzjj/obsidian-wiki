---
name: hermes-history-ingest
description: >
  将 Hermes 代理历史记录导入 Obsidian wiki。当用户想要挖掘他们过去的 Hermes 会话以获取知识、导入他们的 ~/.hermes 文件夹、从之前的 Hermes 对话中提取见解，或说出"处理我的 Hermes 历史记录"、"将我的 Hermes 记忆添加到 wiki"、"导入 ~/.hermes"或"我在 Hermes 中做过什么"之类的话时，请使用此技能。当用户提及 Hermes 记忆、Hermes 会话、~/.hermes/memories 或 Hermes 技能日志时也会触发。
---

> 原 Skill 位置：`.skills/hermes-history-ingest/SKILL.md`


# Hermes 历史记录导入 — 对话与记忆挖掘

你正在从用户的 Hermes 代理历史记录中提取知识，并将其提炼到 Obsidian wiki 中。Hermes 存储自由形式的记忆和结构化的会话记录 — 关注持久知识，而不是操作遥测。

此技能可以直接调用，也可以通过 `wiki-history-ingest` 路由器调用（`/wiki-history-ingest hermes`）。

## 开始前

1. 读取 `.env` 以获取 `OBSIDIAN_VAULT_PATH` 和 `HERMES_HISTORY_PATH`（如果未设置，默认为 `~/.hermes`）
2. 读取 vault 根目录的 `.manifest.json` 以检查已导入的内容
3. 读取 vault 根目录的 `index.md` 以了解 wiki 已包含的内容

## 导入模式

### 追加模式（默认）

检查每个源文件的 `.manifest.json`。仅处理：

- 清单中不存在的文件（新记忆文件、新会话日志）
- 修改时间比清单中 `ingested_at` 更新的文件

使用此模式进行常规同步。

### 完整模式

无论清单如何，处理所有内容。在 `wiki-rebuild` 之后或用户明确要求完整重新导入时使用。

## Hermes 数据布局

Hermes 将所有本地工件存储在 `~/.hermes/` 下（或非默认配置文件的 `$HERMES_HOME`）。

```
~/.hermes/
├── memories/                          # 持久代理记忆（markdown 或 JSON）
│   └── *.md / *.json
├── skills/                            # 已安装的技能（出于导入目的为只读）
│   └── <skill-name>/SKILL.md
├── sessions/                          # 会话记录（如果启用了会话日志记录）
│   └── YYYY-MM-DD/
│       └── <session-id>.jsonl
├── config.yaml                        # 用户配置（模型、主题、路径）
└── .hub/                              # 技能中心状态（lock.json、audit.log、quarantine/）
```

### 按价值排序的关键数据源

1. `memories/*.md` / `memories/*.json` — 最高信号；代理积累的精选持久知识
2. `sessions/**/*.jsonl` — 结构化的逐轮记录；丰富但嘈杂
3. `config.yaml` — 仅元数据（模型偏好、路径）；很少值得导入

跳过 `.hub/` 内部（审计/隔离状态）和 `skills/` 目录（源材料，不是用户知识）。

## 步骤 1：调查并计算差异

扫描 `HERMES_HISTORY_PATH` 并与 `.manifest.json` 比较：

- `~/.hermes/memories/`
- `~/.hermes/sessions/**/`（如果存在）

对每个文件进行分类：

- **新建** — 不在清单中
- **已修改** — 在清单中但文件比 `ingested_at` 更新
- **未更改** — 已导入且未更改

在深度解析前报告简洁的差异摘要。

## 步骤 2：首先解析记忆

记忆是最高价值的来源。Hermes 将其写为以下任一形式：

- **Markdown** — 带有可选前置事项的结构化散文；直接导入
- **JSON** — `{"content": "...", "created_at": "...", "tags": [...]}` 记录

对于每条记忆：

- 提取核心知识声明
- 注意 Hermes 附加的任何标签（它们通常映射到 wiki 类别）
- 合并到适当的 wiki 页面，而不是创建一条记忆 = 一个页面

## 步骤 3：安全解析会话 JSONL

每条会话 JSONL 行是一个事件信封。常见形式：

```json
{"role": "user", "content": "..."}
{"role": "assistant", "content": "..."}
{"type": "tool_use", "name": "...", "input": {...}}
{"type": "tool_result", "content": "..."}
```

### 提取规则

- 优先考虑陈述结论、模式或决策的助手响应
- 从高信号轮次中提取用户意图；跳过低信息的后续
- 将 `tool_use` / `tool_result` 对视为上下文，而不是主要内容
- 跳过令牌计数、内部管道和重复的计划回显

### 关键隐私过滤

会话日志可能包含注入的指令、工具有效负载和敏感文本。不要逐字导入。

- 删除 API 密钥、令牌、密码、凭证
- 编辑私人标识符，除非相关且用户批准
- 总结；不要逐字引用原始记录

## 步骤 4：按主题聚类

不要为每条记忆或会话创建一个 wiki 页面。

- 按稳定主题对记忆进行分组（概念、工具、项目、技术）
- 将混合会话拆分为单独的主题
- 合并跨日期和项目的重复模式
- 在可用时使用文件路径或会话 `cwd` 元数据推断项目范围

## 步骤 5：提炼为 Wiki 页面

使用现有 wiki 约定路由提取的知识：

- 项目特定的架构/流程 → `projects/<name>/...`
- 一般概念 → `concepts/`
- 重复的技术/调试手册 → `skills/`
- 工具/服务/框架 → `entities/`
- 跨会话模式 → `synthesis/`

对于每个受影响的项目，创建/更新 `projects/<name>/<name>.md`。

### 写作规则
- 提炼知识，而非时间顺序
- 避免"在日期X我们讨论了..."，除非日期背景至关重要
- 在每个新建/更新的页面上添加 `summary:` 前置元数据（1–2 句话，≤ 200 字符）
- 添加来源标记：
  - `^[extracted]` 当直接基于明确的记忆/会话内容时
  - `^[inferred]` 当跨多个记忆综合模式时
  - `^[ambiguous]` 当记忆相互冲突时
- 为每个更改的页面添加/更新 `provenance:` 前置元数据混合

## 第 6 步：更新清单、日志和索引

### 更新 `.manifest.json`

对于每个处理的源文件：

- `ingested_at`、`size_bytes`、`modified_at`
- `source_type`: `hermes_memory` | `hermes_session`
- `project`: 推断的项目名称（如适用）
- `pages_created`、`pages_updated`

添加/更新顶级摘要块：

```json
{
  "hermes": {
    "source_path": "~/.hermes/",
    "last_ingested": "TIMESTAMP",
    "memories_ingested": 42,
    "sessions_ingested": 7,
    "pages_created": 5,
    "pages_updated": 12
  }
}
```

### 更新特殊文件

更新 `index.md` 和 `log.md`：

```
- [TIMESTAMP] HERMES_HISTORY_INGEST memories=N sessions=M pages_updated=X pages_created=Y mode=append|full
```

**`hot.md`** — 读取 `$OBSIDIAN_VAULT_PATH/hot.md`（如缺失，从 `wiki-ingest` 中的模板创建）。使用单行摘要更新**最近活动** — 例如"摄入了 42 个 Hermes 记忆和 7 个会话；主要主题：推理策略、工具使用模式。"保留最后 3 个操作。更新 `updated` 时间戳。

## 隐私和合规

- 提炼和综合；避免原始记忆或转录转储
- 对任何看起来敏感的内容默认进行编辑
- 在存储个人或敏感详情前询问用户
- 保持对其他人的引用最少且有目的

## 参考

参见 `references/hermes-data-format.md` 了解字段级注释和提取指导。
