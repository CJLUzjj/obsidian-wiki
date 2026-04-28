> 原 Skill 位置：`.skills/hermes-history-ingest/references/hermes-data-format.md`

# Hermes Agent — 数据格式参考

在 wiki 摄取期间解析 `~/.hermes/` 工件的字段级说明。

## 缓存根目录

`~/.hermes/` — 或非默认配置文件的 `$HERMES_HOME`。下面的所有路径都相对于此根目录。

## memories/

每个文件是代理持久化的一个离散记忆。

### Markdown 记忆 (`*.md`)

可选的 YAML 前置元数据，然后是正文：

```markdown
---
tags: [python, async, debugging]
created_at: 2026-03-10T14:22:00Z
project: my-api
---
When using `asyncio.gather` with return_exceptions=True, failed tasks return the exception
object rather than raising — check `isinstance(result, Exception)` on each item.
```

感兴趣的字段：
- `tags` — 直接映射到 wiki 标签；规范化为 kebab-case
- `created_at` — 用于来源 / 日志分类决策
- `project` — 设置时路由到 `projects/<project>/`

### JSON 记忆 (`*.json`)

```json
{
  "content": "...",
  "created_at": "2026-03-10T14:22:00Z",
  "tags": ["python", "async"],
  "project": "my-api",
  "source": "session:abc123"
}
```

字段语义与 markdown 变体相同。`source` 链接回原始会话。

## sessions/

仅在启用会话日志记录时出现（`config.yaml: logging.sessions: true`）。

### 目录布局

```
sessions/
└── 2026-03-10/
    └── abc123.jsonl
```

### JSONL 行架构

**用户 / 助手轮次：**

```json
{"role": "user",      "content": "How do I debounce a React input?"}
{"role": "assistant", "content": "Use useCallback + useEffect with a setTimeout..."}
```

**工具使用：**

```json
{
  "type": "tool_use",
  "id": "tu_abc",
  "name": "read_file",
  "input": {"path": "/home/ubuntu/project/src/App.tsx"}
}
```

**工具结果：**

```json
{
  "type": "tool_result",
  "tool_use_id": "tu_abc",
  "content": "..."
}
```

**会话元数据（第一行）：**

```json
{
  "type": "session_meta",
  "id": "abc123",
  "cwd": "/home/ubuntu/projects/my-app",
  "model": "claude-sonnet-4-6",
  "started_at": "2026-03-10T14:00:00Z"
}
```

`cwd` 是最可靠的项目推断信号 — 使用它将知识路由到正确的 `projects/<name>/` 页面。

## config.yaml

摄取时很少有用。需要时的有用字段：

```yaml
model: claude-sonnet-4-6
hermes_home: ~/.hermes        # resolved path, respects $HERMES_HOME
logging:
  sessions: true              # whether session JSONL files are written
  memories: true              # whether memories are persisted
```

## .hub/

Skills Hub 状态。**摄取期间完全跳过。** 包含：

- `lock.json` — 已安装的技能清单（非用户知识）
- `audit.log` — 安装/更新历史
- `quarantine/` — 等待审查的标记技能

## 提取优先级

| 来源 | 信号 | 噪声 |
|---|---|---|
| `memories/*.md` | 高 — 精选、稳定 | 低 |
| `memories/*.json` | 高 — 结构化 | 低 |
| `sessions/**/*.jsonl` — 助手轮次 | 中 | 中 |
| `sessions/**/*.jsonl` — 工具对 | 低 | 高 |
| `config.yaml` | 非常低 | — |
| `.hub/` | 无 | — |
