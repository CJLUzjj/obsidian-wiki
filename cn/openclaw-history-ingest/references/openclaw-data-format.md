> 原 Skill 位置：`.skills/openclaw-history-ingest/references/openclaw-data-format.md`

# OpenClaw Agent — 数据格式参考

在 wiki 摄取期间解析 `~/.openclaw/` 工件的字段级说明。

## 缓存根目录

`~/.openclaw/` — 下面的所有路径都相对于此根目录。

## workspace/MEMORY.md

纯 markdown。无需前置元数据 — 结构因用户和代理配置而异。通常如下所示：

```markdown
# Memory

## User Preferences
- Prefers concise responses without trailing summaries
- Uses pnpm over npm

## Projects
### my-api
- FastAPI app, deployed on Fly.io
- Uses Postgres via Supabase

## Patterns
- Debugging: always check logs before code changes
```

这是整个 `~/.openclaw/` 树中最有价值的单一来源。在接触会话日志之前，请完整阅读。

## workspace/memory/YYYY-MM-DD.md

每日笔记文件。由 OpenClaw 在每天开始时自动生成。格式：

```markdown
# 2026-04-15

## Session: my-api refactor
- Rewrote auth middleware to use JWT instead of sessions
- Decision: keep refresh tokens in httpOnly cookies

## Session: obsidian-wiki
- Added cross-linker skill
- Fixed broken wikilinks in concepts/
```

今天和昨天的文件会自动加载到每个会话中。超过约 7 天的文件信号急剧下降。

## workspace/DREAMS.md

可选。某些 OpenClaw 配置会在此处生成每日末总结。纯 markdown。将其视为 MEMORY.md 的较低优先级补充 — 浏览以查找 MEMORY.md 中尚未捕获的新见解。

## agents/\<agentId\>/sessions/sessions.json

会话索引。JSON 数组：

```json
[
  {
    "id": "abc123",
    "name": "my-api refactor",
    "created_at": "2026-04-15T10:00:00Z",
    "updated_at": "2026-04-15T12:30:00Z",
    "message_count": 47,
    "agent_id": "default"
  }
]
```

用途：
- 在打开 JSONL 文件之前构建会话清单
- 按 `updated_at` 排序优先级（最近 = 最高信号）
- 将会话 ID 映射到人类可读的名称

## agents/\<agentId\>/sessions/\<sessionId\>.jsonl

每个会话的记录。JSONL，仅追加。每行一个 JSON 对象：

**用户轮次：**
```json
{"role": "user", "content": "How do I debounce a React input?", "timestamp": "2026-04-15T10:01:00Z"}
```

**助手轮次：**
```json
{"role": "assistant", "content": "Use useCallback + useEffect with a clearTimeout...", "timestamp": "2026-04-15T10:01:02Z"}
```

**工具调用：**
```json
{"role": "tool", "name": "read_file", "input": {"path": "/home/ubuntu/app/src/App.tsx"}, "timestamp": "2026-04-15T10:01:05Z"}
```

**工具结果：**
```json
{"role": "tool_result", "name": "read_file", "content": "...", "timestamp": "2026-04-15T10:01:05Z"}
```

`role` 是主要分发字段。`timestamp` 为 ISO 8601 格式。`content` 可以是字符串或结构化对象（用于多部分响应）。

## agents/\<agentId\>/sessions/\<sessionId\>-topic-\<threadId\>.jsonl

Telegram 主题变体 — 与基础会话 JSONL 相同的架构。`-topic-<threadId>` 后缀标识生成会话的 Telegram 线程。解析方式与常规会话文件相同。

## openclaw.json

全局配置。对摄取很少有用。如需要，感兴趣的字段：

```json
{
  "agents": {
    "defaults": {
      "workspace": "~/.openclaw/workspace",
      "bootstrapMaxChars": 20000
    }
  },
  "skills": {
    "load": {
      "extraDirs": []
    }
  }
}
```

如果非默认，`agents.defaults.workspace` 是 MEMORY.md 和每日笔记的规范路径。

## 引导文件优先级（供参考）

OpenClaw 在会话开始时按此顺序加载上下文文件：

| 优先级 | 文件 | 说明 |
|---|---|---|
| 10 | `AGENTS.md` | 始终启用的项目说明 |
| 20 | `SOUL.md` | 代理身份 |
| 30 | `IDENTITY.md` | 代理角色 |
| 40 | `USER.md` | 用户档案 |
| 50 | `TOOLS.md` | 工具配置 |
| 60 | `BOOTSTRAP.md` | 自定义引导 |
| 70 | `MEMORY.md` | 长期记忆（工作区副本） |

所有文件在每个文件的 `bootstrapMaxChars`（默认 20,000 字符）处截断。

## 提取优先级

| 来源 | 信号 | 噪声 |
|---|---|---|
| `workspace/MEMORY.md` | 非常高 — 精选、持久 | 非常低 |
| `workspace/memory/YYYY-MM-DD.md`（最近） | 高 — 活跃上下文 | 低 |
| `workspace/DREAMS.md` | 中等 — 总结 | 低 |
| `workspace/memory/YYYY-MM-DD.md`（旧） | 低 — 陈旧 | 中等 |
| `sessions/*.jsonl` — 助手轮次 | 中等 | 中等 |
| `sessions/*.jsonl` — 工具对 | 低 | 高 |
| `openclaw.json` | 非常低 | — |
| `credentials/` | 无 — 跳过 | — |
