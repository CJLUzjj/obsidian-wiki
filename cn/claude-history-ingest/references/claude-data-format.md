> 原 Skill 位置：`.skills/claude-history-ingest/references/claude-data-format.md`

# Claude 代码数据格式 — 详细参考

## 项目目录

`~/.claude/projects/` 包含用户使用 Claude Code 打开的每个项目的一个目录。目录名称编码绝对路径：

```
/Users/name/Documents/projects/my-app → -Users/name/Documents/projects/my-app
```

恢复原始路径：将前导 `-` 替换为 `/`，然后谨慎替换剩余的 `-`（破折号也出现在目录名称中）。会话/对话数据中的 `cwd` 字段提供规范路径。

### 对话 JSONL 文件

位于 `~/.claude/projects/<project-dir>/<session-uuid>.jsonl`。

每一行是一个事件。相关事件类型：

| `type`                  | 说明                    | 值得阅读？                           |
| ----------------------- | ----------------------- | ------------------------------------ |
| `user`                  | 用户消息                | 是 — 这是用户提问/说的内容           |
| `assistant`             | 助手响应                | 是 — 从内容中提取 `text` 块          |
| `progress`              | 工具执行进度            | 否 — 内部机制                        |
| `file-history-snapshot` | 会话开始时的文件状态    | 否 — 仅文件列表                      |

#### 用户消息结构

```json
{
  "type": "user",
  "message": { "role": "user", "content": "the user's message as a string" },
  "timestamp": "2026-03-15T10:30:00.000Z",
  "sessionId": "uuid",
  "cwd": "/Users/name/Documents/projects/my-app"
}
```

#### 助手消息结构

```json
{
  "type": "assistant",
  "message": {
    "role": "assistant",
    "content": [
      { "type": "thinking", "text": "internal reasoning (skip this)" },
      { "type": "text", "text": "The actual visible response" },
      {
        "type": "tool_use",
        "id": "...",
        "name": "Read",
        "input": { "file_path": "..." }
      }
    ]
  },
  "timestamp": "2026-03-15T10:30:05.000Z"
}
```

**提取策略：** 仅从助手内容数组中提取 `text` 类型块。`thinking` 块是内部推理，`tool_use` 块是机械操作 — 两者都不会增加 wiki 价值的知识。

### 内存文件

位于 `~/.claude/projects/<project-dir>/memory/`。

每个内存文件都有 YAML 前置元数据：

```markdown
---
name: descriptive-name
description: one-line summary used for relevance matching
type: user|feedback|project|reference
---

The memory content. For feedback/project types, structured as:
rule/fact, then **Why:** and **How to apply:** lines.
```

**内存类型及其 wiki 价值：**

| 类型        | 包含内容                             | 映射到 wiki                                    |
| ----------- | ------------------------------------ | ---------------------------------------------- |
| `user`      | 用户的角色、偏好、专业知识           | 关于用户的实体页面，或其他页面的上下文         |
| `feedback`  | 工作流程更正和确认                   | 技能页面 — "如何有效工作"                      |
| `project`   | 活跃工作、目标、决策、截止日期       | 项目的实体页面                                 |
| `reference` | 指向外部资源的指针                   | 参考页面                                       |

每个内存目录中的 `MEMORY.md` 是一个包含单行摘要的索引。首先阅读它以进行分类。

### 会话元数据

位于 `~/.claude/sessions/<pid>.json`。轻量级元数据：

```json
{
  "pid": 12345,
  "sessionId": "uuid",
  "cwd": "/Users/name/Documents/projects/my-app",
  "startedAt": "2026-03-15T10:30:00.000Z",
  "kind": "interactive",
  "entrypoint": "cli"
}
```

用于构建用户何时处理什么的时间线。

### 全局历史

`~/.claude/history.jsonl` — 所有会话的仅追加日志。用于时间线重建。

## 处理顺序

为了最高效率：

1. **MEMORY.md 索引** — 快速分类每个项目知道什么
2. **单个内存文件** — 预蒸馏知识，信噪比最高
3. **对话 JSONL** — 丰富但冗长，有选择地处理
4. **会话元数据** — 仅在需要时间线上下文时使用
