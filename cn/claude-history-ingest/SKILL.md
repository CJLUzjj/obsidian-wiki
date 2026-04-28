---
name: claude-history-ingest
description: >
  将 Claude Code 对话历史导入到 Obsidian wiki 中。当用户想要挖掘他们过去的 Claude 对话以获取知识、导入他们的 ~/.claude 文件夹、从之前的编码会话中提取见解，或说出"处理我的 Claude 历史"、"将我的对话添加到 wiki"、"我之前与 Claude 讨论过什么"之类的话时，使用此技能。当用户提及他们的 .claude 文件夹、Claude 项目、会话数据、过去的对话日志、本地代理模式会话或审计日志时也会触发。
---

> 原 Skill 位置：`.skills/claude-history-ingest/SKILL.md`


# Claude 历史导入 — 对话挖掘

你正在从用户过去的 Claude Code 对话中提取知识，并将其提炼到 Obsidian wiki 中。对话内容丰富但杂乱无章 — 你的工作是找到有价值的信息并编译它。

此技能可以直接调用，也可以通过 `wiki-history-ingest` 路由器调用（`/wiki-history-ingest claude`）。

## 开始前

1. 读取 `.env` 以获取 `OBSIDIAN_VAULT_PATH` 和 `CLAUDE_HISTORY_PATH`（默认为 `~/.claude`）
2. 读取 vault 根目录的 `.manifest.json` 以检查已导入的内容
3. 读取 vault 根目录的 `index.md` 以了解 wiki 已包含的内容

## 导入模式

### 追加模式（默认）

检查每个源文件（对话 JSONL、内存文件）的 `.manifest.json`。仅处理：

- 清单中不存在的文件（新对话、新内存文件、新项目）
- 修改时间比清单中 `ingested_at` 更新的文件

这通常是你想要的 — 用户运行了几个新会话，想要捕获增量。

### 完整模式

无论清单如何，处理所有内容。在 `wiki-rebuild` 后或用户明确要求时使用。

## Claude Code 数据布局

Claude Code 在两个位置存储数据。扫描**两个位置**。

### 源 1：`~/.claude/`（CLI 会话）

```
~/.claude/
├── projects/                          # 每个项目的目录
│   ├── -Users-name-project-a/         # 路径派生的名称（斜杠 → 破折号）
│   │   ├── <session-uuid>.jsonl       # 对话数据（JSONL）
│   │   └── memory/                    # 结构化内存
│   │       ├── MEMORY.md              # 内存索引
│   │       ├── user_*.md              # 用户档案内存
│   │       ├── feedback_*.md          # 工作流反馈内存
│   │       └── project_*.md           # 项目上下文内存
│   ├── -Users-name-project-b/
│   │   └── ...
├── sessions/                          # 会话元数据（JSON）
│   └── <pid>.json                     # {pid, sessionId, cwd, startedAt, kind, entrypoint}
├── history.jsonl                      # 全局会话历史
├── tasks/                             # 子代理任务数据
├── plans/                             # 保存的计划
└── settings.json
```

### 源 2：`~/Library/Application Support/Claude/local-agent-mode-sessions/`（桌面应用代理会话）

Claude 桌面应用在此处存储本地代理模式会话。结构深度嵌套：

```
~/Library/Application Support/Claude/local-agent-mode-sessions/
└── <outer-uuid>/
    └── <inner-uuid>/
        ├── local_<session-uuid>.json          # 会话元数据
        └── local_<session-uuid>/
            ├── audit.jsonl                    # 审计日志 — 工具调用、文件读取、运行的命令
            └── .claude/
                └── projects/
                    └── <path-encoded-name>/   # 与 ~/.claude/projects/ 相同的路径编码
                        └── <uuid>.jsonl       # 对话记录（与 CLI 相同的 JSONL 格式）
```

**如何找到所有本地代理模式会话：**

```bash
# 查找所有会话元数据文件
find ~/Library/Application\ Support/Claude/local-agent-mode-sessions -name "local_*.json" -maxdepth 4

# 查找所有审计日志
find ~/Library/Application\ Support/Claude/local-agent-mode-sessions -name "audit.jsonl"

# 查找所有对话记录
find ~/Library/Application\ Support/Claude/local-agent-mode-sessions -name "*.jsonl" -path "*/.claude/projects/*"
```

**会话元数据（`local_<uuid>.json`）** — JSON 文件，包含 `sessionId`、`cwd`、`startedAt`、`model`、`title` 等字段。在打开记录前先读取此文件以了解会话上下文。

**审计日志（`audit.jsonl`）** — 每一行是一条代理操作的 JSON 记录：工具调用（Read、Write、Bash、Edit）、文件访问、执行的 shell 命令、MCP 调用。用于理解*代理实际做了什么* — 通常比对话文本本身提供更丰富的信号。字段：`type`、`toolName`、`input`、`output`、`timestamp`、`sessionId`。

**对话记录（`.claude/projects/.../<uuid>.jsonl`）** — 与 CLI 对话 JSONL 格式相同。以与 `~/.claude/projects/*/*.jsonl` 相同的方式解析。

### 关键数据源按价值排序（两个位置合并）：

1. **内存文件**（`~/.claude/projects/*/memory/*.md`）— 预先提炼，已适合 wiki。黄金。
2. **对话 JSONL**（`~/.claude/projects/*/*.jsonl` 和桌面应用记录）— 完整对话记录。内容丰富但杂乱。
3. **审计日志**（桌面会话中的 `audit.jsonl`）— 工具调用级别的操作记录。用于提取具体操作、文件模式和命令模式，即使对话稀疏也有用。
4. **会话元数据**（`sessions/*.json` 和 `local_*.json`）— 告诉你哪个项目、何时以及什么 CWD。

## 步骤 1：调查并计算增量

扫描两个数据位置并与 `.manifest.json` 比较：
```bash
# --- 源 1: CLI 会话 (~/.claude) ---
# 查找所有项目
Glob: ~/.claude/projects/*/

# 查找内存文件（最高价值）
Glob: ~/.claude/projects/*/memory/*.md

# 查找对话 JSONL 文件
Glob: ~/.claude/projects/*/*.jsonl

# --- 源 2: 桌面应用本地代理模式会话 ---
DESKTOP_SESSIONS="$HOME/Library/Application Support/Claude/local-agent-mode-sessions"

# 会话元数据
find "$DESKTOP_SESSIONS" -name "local_*.json" -maxdepth 4

# 审计日志
find "$DESKTOP_SESSIONS" -name "audit.jsonl"

# 对话记录
find "$DESKTOP_SESSIONS" -name "*.jsonl" -path "*/.claude/projects/*"
```

构建统一的清单并对每个文件进行分类：

- **新增** — 不在清单中 → 需要摄入
- **已修改** — 在清单中但文件较新 → 需要重新摄入
- **未变更** — 在清单中且未修改 → 在追加模式下跳过

向用户报告："找到 X 个 CLI 项目，Y 个桌面会话。内存文件：A。对话：B。审计日志：C。差异：D 个新增，E 个已修改。"

## 步骤 2: 首先摄入内存文件

内存文件已使用 YAML 前置元数据结构化：

```markdown
---
name: memory-name
description: one-line description
type: user|feedback|project|reference
---

内存内容在此。
```

对于每个内存文件：

- 读取并解析前置元数据
- `user` 类型 → 输入到关于用户的实体页面或其领域的概念页面
- `feedback` 类型 → 输入到技能页面（工作流模式、什么有效、什么无效）
- `project` 类型 → 输入到项目的实体页面
- `reference` 类型 → 输入到指向外部资源的参考页面

每个项目中的 `MEMORY.md` 索引文件是快速摘要 — 首先读取它以决定哪些单个内存文件值得完整阅读。

## 步骤 3: 解析对话 JSONL

每个 JSONL 文件是一个对话会话。每行是一个 JSON 对象：

```json
{
  "type": "user|assistant|progress|file-history-snapshot",
  "message": {
    "role": "user|assistant",
    "content": "text string"
  },
  "uuid": "...",
  "timestamp": "2026-03-15T10:30:00.000Z",
  "sessionId": "...",
  "cwd": "/path/to/project",
  "version": "2.1.59"
}
```

对于助手消息，`content` 可能是内容块的数组：

```json
{
  "content": [
    {"type": "thinking", "text": "..."},
    {"type": "text", "text": "实际响应..."},
    {"type": "tool_use", "name": "Read", "input": {...}}
  ]
}
```

**从对话中提取的内容：**

- 仅筛选 `type: "user"` 和 `type: "assistant"` 条目
- 对于助手条目，提取 `text` 块（跳过 `thinking` 和 `tool_use` — 这些是噪音）
- `cwd` 字段告诉你这个对话属于哪个项目
- 项目目录名称（例如 `-Users-name-Documents-projects-my-app`）告诉你项目路径

**跳过这些：**

- `type: "progress"` — 内部代理进度更新
- `type: "file-history-snapshot"` — 文件状态跟踪
- 子代理对话（在 `subagents/` 子目录下）— 除非用户特别要求

## 步骤 3b: 解析审计日志（仅限桌面会话）

对于在 `local-agent-mode-sessions/` 下找到的每个 `audit.jsonl`，逐行读取。每行是一个代理操作的 JSON 记录：

```json
{
  "type": "tool_call",
  "toolName": "Bash",
  "input": {"command": "npm test"},
  "output": "...",
  "timestamp": "2026-04-10T14:22:00Z",
  "sessionId": "..."
}
```

**从审计日志中提取的内容：**

- **文件访问模式** — 代理反复读取或编辑哪些文件？这些是项目中的高价值文件。将它们记录为项目参考。
- **Shell 命令** — 重复出现的 Bash 命令揭示项目的构建/测试/部署工作流。将这些提炼为 `skills/` 页面（例如"此项目如何构建和测试"）。
- **工具调用序列** — 如果代理总是以特定顺序执行读取 → 编辑 → Bash，那就是值得捕获的工作流模式。
- **错误模式** — 失败的工具调用（非零退出代码、错误输出）揭示痛点、已知的粗糙边缘或重复出现的错误。
- **MCP 工具调用** — 对 MCP 工具的调用揭示项目集成的外部服务和 API。

**从审计日志中跳过：**

- 没有模式的常规文件读取（例如一次性读取配置文件）
- 只是噪音的工具输出（长堆栈跟踪、详细日志）— 总结错误类别，而不是完整输出
- 命令参数或输出中看起来像秘密、令牌或凭证的任何内容

**与对话记录交叉参考：** 审计日志告诉你*发生了什么*；对话告诉你*为什么*。当两者对同一会话都可用时，一起使用它们 — 审计日志将对话基于具体操作。

在处理审计日志之前读取配对的 `local_<uuid>.json` 会话元数据 — 它为你提供 `cwd`、`startedAt` 和 `title` 来为操作提供上下文。

## 步骤 4: 按主题聚类

不要为每个对话创建一个 wiki 页面。相反：

- 跨对话**按主题**分组提取的知识
- 一个关于"调试身份验证 + 设置 CI"的对话 → 两个独立主题
- 三个不同日期关于"React 性能"的对话 → 一个合并主题
- 项目目录名称为你提供自然的第一级分组

## 步骤 5: 提炼为 Wiki 页面
每个 Claude 项目都映射到保险库中的一个项目目录。来自 `~/.claude/projects/` 的项目目录名称编码了原始路径 — 解码它以获得干净的项目名称：

```
-Users/Documents/projects/my-Project   → myproject
-Users/Documents/projects/Another-app  → anotherapp
```

### 项目特定知识 vs. 全局知识

| 你发现的内容                   | 放置位置                    | 示例                                                |
| ------------------------------ | --------------------------- | --------------------------------------------------- |
| 项目架构决策                   | `projects/<name>/concepts/` | `projects/my-project/concepts/main-architecture.md` |
| 项目特定调试                   | `projects/<name>/skills/`   | `projects/my-project/skills/api-rate-limiting.md`   |
| 用户学到的通用概念             | `concepts/`（全局）         | `concepts/react-server-components.md`               |
| 跨项目的重复问题               | `skills/`（全局）           | `skills/debugging-hydration-errors.md`              |
| 使用的工具/服务                | `entities/`（全局）         | `entities/vercel-functions.md`                      |
| 跨多个对话的模式               | `synthesis/`（全局）        | `synthesis/common-debugging-patterns.md`            |

对于每个有内容的项目，在 `projects/<name>/<name>.md` 处创建或更新项目概览页面 — **以项目名称命名，而不是 `_project.md`**。Obsidian 的图表视图使用文件名作为节点标签，所以 `_project.md` 会导致每个项目在图表中显示为 `_project`。将其命名为 `<name>.md` 可以为每个项目提供不同的、可读的节点名称。

**重要：** 提炼_知识_，而不是对话。不要写"在 3 月 15 日的对话中，用户询问了 X。"写知识本身，以对话作为来源归属。

**在每个新建/更新的页面上写一个 `summary:` 前置字段** — 1–2 句话，≤200 字符，回答"这个页面是关于什么的？"供还没打开它的读者。`wiki-query` 的廉价检索路径读取此字段以避免打开页面正文。

**标记出处** 按照 `llm-wiki` 中的约定（出处标记部分）：

- **记忆文件** 大多是提取的 — 用户手工编写，已经过提炼。将记忆衍生的声明视为提取的，除非你在拼接来自多个记忆文件的声明。
- **对话提炼** 大多是推断的。你在综合来自许多对话轮次的连贯声明，通常填补隐含的推理。对综合模式、跨会话的泛化和"用户真正的意思"解释大量应用 `^[inferred]`。
- 当用户在会话间改变主意或助手和用户相互矛盾且解决方案不清楚时，使用 `^[ambiguous]`。
- 在每个新建/更新的页面上写一个 `provenance:` 前置块，总结大致的混合情况。

## 第 6 步：更新清单、日志和特殊文件

### 更新 `.manifest.json`

对于每个处理的源文件，添加/更新其条目，包含：

- `ingested_at`、`size_bytes`、`modified_at`
- `source_type`：`"claude_conversation"`、`"claude_memory"`、`"claude_audit_log"`、`"claude_desktop_session"` 之一
- `project`：解码后的项目名称
- `pages_created` 和 `pages_updated` 列表

同时更新清单的 `projects` 部分：

```json
{
  "project-name": {
    "source_path": "~/.claude/projects/-Users-...",
    "vault_path": "projects/project-name",
    "last_ingested": "TIMESTAMP",
    "conversations_ingested": 5,
    "conversations_total": 8,
    "memory_files_ingested": 3,
    "desktop_sessions_ingested": 2,
    "audit_logs_ingested": 2
  }
}
```

### 创建日志条目 + 更新特殊文件

按标准流程更新 `index.md` 和 `log.md`：

```
- [TIMESTAMP] CLAUDE_HISTORY_INGEST projects=N conversations=M desktop_sessions=D audit_logs=A pages_updated=X pages_created=Y mode=append|full
```

**`hot.md`** — 读取 `$OBSIDIAN_VAULT_PATH/hot.md`（如果缺失，从 `wiki-ingest` 中的模板创建）。用一行摘要更新**最近活动** — 例如"在 2 个项目中摄取了 5 个 Claude 对话；浮现了 API 设计和测试策略中的模式。"保留最后 3 个操作。如果任何进行中的项目现在理解得更好，更新**活跃线程**。更新 `updated` 时间戳。

## 隐私

- 提炼和综合 — 不要逐字复制原始对话文本
- 跳过任何看起来像秘密、API 密钥、密码、令牌的内容
- 如果你遇到个人/敏感内容，在包含它之前询问用户
- 用户的对话可能会提及其他人 — 要谨慎考虑什么进入维基

## 参考

有关数据结构的更多详情，请参见 `references/claude-data-format.md`。
