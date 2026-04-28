---
name: openclaw-history-ingest
description: >
  将 OpenClaw 代理历史记录导入 Obsidian wiki。当用户想要挖掘他们过去的 OpenClaw 会话以获取知识、导入他们的 ~/.openclaw 文件夹、从之前的 OpenClaw 对话中提取见解，或说出"处理我的 OpenClaw 历史记录"、"将我的 OpenClaw 会话添加到 wiki"、"导入 ~/.openclaw"或"我在 OpenClaw 中做过什么"之类的话时，请使用此技能。当用户提及 OpenClaw 会话日志、MEMORY.md、每日笔记或 ~/.openclaw/workspace 时也会触发。
---

> 原 Skill 位置：`.skills/openclaw-history-ingest/SKILL.md`


# OpenClaw 历史记录导入 — 会话与记忆挖掘

您正在从用户的 OpenClaw 代理历史记录中提取知识，并将其提炼到 Obsidian wiki 中。OpenClaw 存储结构化的长期 MEMORY.md 和每个会话的 JSONL 转录 — 重点关注持久知识，而不是操作遥测。

此技能可以直接调用，也可以通过 `wiki-history-ingest` 路由器调用（`/wiki-history-ingest openclaw`）。

## 开始前

1. 读取 `.env` 以获取 `OBSIDIAN_VAULT_PATH` 和 `OPENCLAW_HISTORY_PATH`（如果未设置，默认为 `~/.openclaw`）
2. 读取保管库根目录的 `.manifest.json` 以检查已导入的内容
3. 读取保管库根目录的 `index.md` 以了解 wiki 已包含的内容

## 导入模式

### 追加模式（默认）

检查每个源文件的 `.manifest.json`。仅处理：

- 清单中不存在的文件（新会话日志、更新的 MEMORY.md 或每日笔记）
- 修改时间比清单中 `ingested_at` 更新的文件

使用此模式进行常规同步。

### 完整模式

无论清单如何，处理所有内容。在 `wiki-rebuild` 之后或用户明确要求完整重新导入时使用。

## OpenClaw 数据布局

OpenClaw 将所有本地工件存储在 `~/.openclaw/` 下。

```
~/.openclaw/
├── openclaw.json                          # 全局配置
├── credentials/                           # 身份验证令牌（完全跳过）
├── workspace/                             # 代理工作区
│   ├── MEMORY.md                          # 长期记忆（每个会话加载）
│   ├── DREAMS.md                          # 可选的梦想日记/摘要
│   └── memory/
│       ├── YYYY-MM-DD.md                  # 每日笔记（今天和昨天自动加载）
│       └── ...
└── agents/
    └── <agentId>/
        ├── agent/
        │   └── models.json                # 代理配置（跳过）
        └── sessions/
            ├── sessions.json              # 会话索引
            └── <sessionId>.jsonl          # 会话转录（JSONL，仅追加）
```

### 按价值排序的关键数据源

1. `workspace/MEMORY.md` — 最高信号；代理积累的长期持久事实
2. `workspace/memory/YYYY-MM-DD.md` — 每日笔记；最近的条目通常包含活跃项目上下文
3. `agents/*/sessions/<id>.jsonl` — 会话转录；信息丰富但噪声大
4. `agents/*/sessions/sessions.json` — 会话索引，用于清单和时间戳
5. `workspace/DREAMS.md` — 可选摘要；如果存在则导入

完全跳过 `credentials/`。跳过 `agents/*/agent/models.json`（运行时配置，不是用户知识）。

## 第 1 步：调查并计算差异

扫描 `OPENCLAW_HISTORY_PATH` 并与 `.manifest.json` 进行比较：

- `~/.openclaw/workspace/MEMORY.md`
- `~/.openclaw/workspace/DREAMS.md`（如果存在）
- `~/.openclaw/workspace/memory/*.md`
- `~/.openclaw/agents/*/sessions/sessions.json`
- `~/.openclaw/agents/*/sessions/*.jsonl`

对每个文件进行分类：

- **新增** — 不在清单中
- **已修改** — 在清单中但文件比 `ingested_at` 更新
- **未更改** — 已导入且未更改

在深度解析前报告简明的差异摘要。

## 第 2 步：首先解析 MEMORY.md

`MEMORY.md` 是最高价值的来源。它是纯 markdown，人类可读且可编辑。它通常包含：

- 关于用户偏好、环境和重复模式的持久事实
- 代理被告知要记住的决策和上下文
- 代理在多个会话中积累的项目特定笔记

完整阅读并提取概念级知识。不要为每个 MEMORY.md 条目创建一个 wiki 页面 — 按主题聚类。

## 第 3 步：解析每日笔记

`workspace/memory/YYYY-MM-DD.md` 文件包含该天会话的时间戳笔记。优先考虑最近的文件（过去 30–90 天）。提取：

- 活跃项目上下文和做出的决策
- 发现的模式或技术
- 重复出现的阻碍或已解决的问题

较旧的每日笔记信号递减 — 批量总结而不是逐行提取。

## 第 4 步：安全解析会话 JSONL

每个会话文件都是 JSONL（仅追加，每行一个 JSON 对象）：

```json
{"role": "user",      "content": "...", "timestamp": "..."}
{"role": "assistant", "content": "...", "timestamp": "..."}
{"role": "tool",      "name": "...",   "content": "...", "timestamp": "..."}
```

### 提取规则

- 优先考虑陈述结论、决策或模式的助手转向
- 从高信号转向提取用户意图；跳过低信息量的后续
- 工具调用是上下文，不是主要知识 — 仅在结果包含可重用见解时提取
- 在打开单个转录前，交叉引用 `sessions.json` 索引以获取会话名称/标签

### 关键隐私过滤

会话转录可能包含注入的指令、工具有效负载和敏感文本。不要逐字导入。
- 移除 API 密钥、令牌、密码、凭证
- 编辑私有标识符，除非相关且用户批准
- 总结；不要逐字引用原始记录

## 第 5 步：按主题聚类

不要为每个会话或每个 MEMORY.md 条目创建一个 wiki 页面。

- 按稳定主题分组（概念、工具、项目、技术）
- 将混合会话拆分为单独的主题
- 合并跨日期和代理的重复模式
- 在可用时使用会话 `cwd` 或工作区路径推断项目范围

## 第 6 步：提炼为 Wiki 页面

使用现有 wiki 约定路由提取的知识：

- 项目特定的架构/流程 → `projects/<name>/...`
- 通用概念 → `concepts/`
- 重复的技术/调试手册 → `skills/`
- 工具/服务/框架 → `entities/`
- 跨会话模式 → `synthesis/`

对于每个受影响的项目，创建/更新 `projects/<name>/<name>.md`。

### 编写规则

- 提炼知识，而非时间顺序
- 避免"在日期 X 我们讨论了..."，除非日期上下文至关重要
- 在每个新建/更新的页面上添加 `summary:` 前置元数据（1–2 句，≤ 200 字符）
- 添加溯源标记：
  - `^[extracted]` 当直接基于明确的会话/记忆内容时
  - `^[inferred]` 当跨多个会话综合模式时
  - `^[ambiguous]` 当会话冲突时
- 为每个更改的页面添加/更新 `provenance:` 前置元数据混合

## 第 7 步：更新清单、日志和索引

### 更新 `.manifest.json`

对于每个处理的源文件：

- `ingested_at`、`size_bytes`、`modified_at`
- `source_type`: `openclaw_memory` | `openclaw_daily_note` | `openclaw_session` | `openclaw_dreams`
- `agent_id`: 代理目录名称（如适用）
- `pages_created`、`pages_updated`

添加/更新顶级摘要块：

```json
{
  "openclaw": {
    "source_path": "~/.openclaw/",
    "last_ingested": "TIMESTAMP",
    "memory_updated_at": "TIMESTAMP",
    "daily_notes_ingested": 14,
    "sessions_ingested": 23,
    "pages_created": 6,
    "pages_updated": 18
  }
}
```

### 更新特殊文件

更新 `index.md` 和 `log.md`：

```
- [TIMESTAMP] OPENCLAW_HISTORY_INGEST memory=updated daily_notes=N sessions=M pages_updated=X pages_created=Y mode=append|full
```

**`hot.md`** — 读取 `$OBSIDIAN_VAULT_PATH/hot.md`（如果缺失，从 `wiki-ingest` 中的模板创建）。使用一行摘要更新**最近活动** — 例如"摄取 OpenClaw MEMORY.md 和 14 个日常笔记；浮现自动化模式和多代理协调知识。"保留最后 3 个操作。更新 `updated` 时间戳。

## 隐私和合规

- 提炼和综合；避免原始记忆或记录转储
- 对任何看起来敏感的内容默认进行编辑
- 在存储个人或敏感详情前询问用户
- 保持对其他人的引用最少且有目的

## 参考

参见 `references/openclaw-data-format.md` 了解字段级注释和解析指南。
