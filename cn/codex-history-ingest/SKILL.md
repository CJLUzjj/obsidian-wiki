---
name: codex-history-ingest
description: >
  将 Codex CLI 对话历史摄入到 Obsidian wiki 中。当用户想要挖掘他们过去的 Codex 会话以获取知识、导入他们的 ~/.codex 文件夹、从之前的编码会话中提取见解，或说出"处理我的 Codex 历史"、"将我的 Codex 对话添加到 wiki"或"我之前在 Codex 中讨论过什么"之类的话时，请使用此技能。当用户提及 .codex 会话、rollout 文件、session_index.jsonl 或 Codex 转录日志时也会触发。
---

> 原 Skill 位置：`.skills/codex-history-ingest/SKILL.md`


# Codex 历史摄入 — 对话挖掘

您正在从用户过去的 Codex 会话中提取知识，并将其提炼到 Obsidian wiki 中。会话日志内容丰富但噪声大：专注于持久知识，而不是操作遥测。

此技能可以直接调用，也可以通过 `wiki-history-ingest` 路由器调用（`/wiki-history-ingest codex`）。

## 开始前

1. 读取 `.env` 以获取 `OBSIDIAN_VAULT_PATH` 和 `CODEX_HISTORY_PATH`（如果未设置，默认为 `~/.codex`）
2. 读取 vault 根目录的 `.manifest.json` 以检查已摄入的内容
3. 读取 vault 根目录的 `index.md` 以了解 wiki 已包含的内容

## 摄入模式

### 追加模式（默认）

检查每个源文件的 `.manifest.json`。仅处理：

- 清单中不存在的文件（新会话 rollout、新索引文件）
- 修改时间比清单中 `ingested_at` 更新的文件

使用此模式进行常规同步。

### 完整模式

无论清单如何，处理所有内容。在 `wiki-rebuild` 后或用户明确要求完整重新摄入时使用。

## Codex 数据布局

Codex 在 `~/.codex/` 下存储本地工件。

```
~/.codex/
├── sessions/                          # 按日期分类的会话 rollout 日志
│   └── YYYY/MM/DD/
│       └── rollout-<timestamp>-<id>.jsonl
├── archived_sessions/                 # 存档的 rollout 日志
├── session_index.jsonl                # 线程 id/name/updated_at 的轻量级索引
├── history.jsonl                      # 本地转录历史（如果启用持久化）
├── config.toml                        # 用户配置（包含历史设置）
└── state_*.sqlite / logs_*.sqlite     # 运行时数据库（通常跳过）
```

### 按价值排序的关键数据源

1. `session_index.jsonl` — ID、标题和新鲜度的最佳库存源
2. `sessions/**/rollout-*.jsonl` — 丰富的结构化转录事件
3. `history.jsonl` — 有用的备用/时间线辅助（如果启用）

除非用户明确要求，否则避免摄入 SQLite 内部结构。

## 步骤 1：调查并计算增量

扫描 `CODEX_HISTORY_PATH` 并与 `.manifest.json` 比较：

- `~/.codex/session_index.jsonl`
- `~/.codex/sessions/**/rollout-*.jsonl`
- `~/.codex/archived_sessions/**`（可选；仅在用户要求存档历史时）
- `~/.codex/history.jsonl`（可选备用）

对每个文件进行分类：

- **新增** — 不在清单中
- **已修改** — 在清单中但文件比 `ingested_at` 更新
- **未更改** — 已摄入且未更改

在深度解析前报告简明的增量摘要。

## 步骤 2：首先解析会话索引

`session_index.jsonl` 通常包含如下条目：

```json
{"id":"...","thread_name":"...","updated_at":"..."}
```

使用它来：

- 构建规范的会话库存
- 优先处理最近/高信号会话
- 将 rollout ID 映射到人类可读的线程名称

## 步骤 3：安全解析 Rollout JSONL

每个 `rollout-*.jsonl` 行是一个事件信封，包含：

```json
{
  "timestamp": "...",
  "type": "session_meta|turn_context|event_msg|response_item",
  "payload": { ... }
}
```

### 提取规则

- 优先考虑用户意图和助手可见的输出
- 倾向于包含用户/助手消息内容的 `response_item` 记录
- 有选择地使用 `event_msg` 处理有意义的里程碑；忽略纯遥测
- 将 `session_meta` 视为元数据（cwd、model、ids），而非用户知识

### 跳过/噪声过滤器

- 令牌计费事件
- 没有语义内容的工具管道
- 原始命令输出，除非包含可重用的决策/模式
- 重复的计划快照，除非它们添加新颖的决策

### 关键隐私过滤器

Rollout 日志可能包含注入的指令、工具有效负载和敏感文本。不要逐字摄入系统/开发者提示或机密。

- 删除 API 密钥、令牌、密码、凭证
- 编辑私有标识符，除非相关且已批准
- 总结而不是引用原始转录

## 步骤 4：按主题聚类

不要为每个会话创建一个 wiki 页面。

- 跨多个会话按稳定主题分组
- 将混合会话拆分为单独的主题
- 合并跨日期/项目的重复概念
- 使用元数据中的 `cwd` 推断项目范围

## 步骤 5：提炼为 Wiki 页面

使用现有 wiki 约定路由提取的知识：

- 项目特定的架构/流程 -> `projects/<name>/...`
- 通用概念 -> `concepts/`
- 重复的技术/调试手册 -> `skills/`
- 工具/服务 -> `entities/`
- 跨会话模式 -> `synthesis/`

对于每个受影响的项目，创建/更新 `projects/<name>/<name>.md`（项目名称作为文件名，从不使用 `_project.md`）。

### 写作规则
- 提炼知识，而非年代记录
- 避免"在日期X我们讨论了..."的表述，除非日期背景至关重要
- 在每个新增/更新的页面上添加 `summary:` 前置元数据（1-2句，<= 200字符）
- 添加来源标记：
  - `^[extracted]` 当直接基于明确的会话内容时
  - `^[inferred]` 当跨事件/会话综合模式时
  - `^[ambiguous]` 当会话存在冲突时
- 为每个更改的页面添加/更新 `provenance:` 前置元数据混合

## 第6步：更新清单、日志和索引

### 更新 `.manifest.json`

对于每个已处理的源文件：

- `ingested_at`、`size_bytes`、`modified_at`
- `source_type`: `codex_rollout` | `codex_index` | `codex_history`
- `project`: 推断的项目名称（如适用）
- `pages_created`、`pages_updated`

添加/更新顶级项目/会话摘要块：

```json
{
  "project-name": {
    "source_path": "~/.codex/sessions/...",
    "last_ingested": "TIMESTAMP",
    "sessions_ingested": 12,
    "sessions_total": 40,
    "index_updated_at": "TIMESTAMP"
  }
}
```

### 更新特殊文件

更新 `index.md` 和 `log.md`：

```
- [TIMESTAMP] CODEX_HISTORY_INGEST sessions=N pages_updated=X pages_created=Y mode=append|full
```

**`hot.md`** — 读取 `$OBSIDIAN_VAULT_PATH/hot.md`（如缺失，从 `wiki-ingest` 中的模板创建）。使用单行摘要更新**最近活动** — 例如"摄入12个Codex会话；发现CLI工具和shell脚本中的重复模式。"保留最后3个操作。更新 `updated` 时间戳。

## 隐私和合规

- 提炼和综合；避免原始记录转储
- 对任何看起来敏感的内容默认进行编辑
- 在存储个人/敏感详情前询问用户
- 保持对他人的引用最少且有目的

## 参考

参见 `references/codex-data-format.md` 了解字段级解析说明和提取指导。
