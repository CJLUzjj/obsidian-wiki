---
name: wiki-history-ingest
description: >
  对话/会话源的统一维基历史记录入口点。当用户说时使用这个
  “/wiki-history-ingest claude”或“/wiki-history-ingest codex”，或要求提取代理历史记录而无需
  命名基本技能。该路由器向专门的历史技能发送。
---

> 原 Skill 位置：`.skills/wiki-history-ingest/SKILL.md`


# 统一历史记录摄取路由器

这是一个瘦路由器，仅用于**历史源**。它不会取代文档的`wiki-ingest`。

## 子命令

如果用户调用`/wiki-history-ingest <target>`（或等效的文本命令），则直接调度：

|子命令 |路线至 |
|---|---|
| `claude` | `claude-history-ingest` |
| `codex` | `codex-history-ingest` |
| `hermes` | `hermes-history-ingest` |
| `openclaw` | `openclaw-history-ingest` |
| `auto` |使用以下规则从上下文推断 |

## 路由规则

1. 如果用户明确说出`claude`、`codex`、`hermes` 或`openclaw`，则直接路由。
2. 如果用户提供路径/源：
   - `~/.claude` 或 Claude 内存/会话 JSONL 工件 -> `claude-history-ingest`
   - `~/.codex` 或转出/会话索引工件 -> `codex-history-ingest`
   - `~/.hermes` 或 Hermes 记忆/会话工件 -> `hermes-history-ingest`
   - `~/.openclaw` 或 OpenClaw MEMORY.md/session JSONL 工件 -> `openclaw-history-ingest`
3. 如果有歧义，请进行简短的澄清：
   - “我应该摄取`claude`、`codex`、`hermes` 或`openclaw` 历史记录吗？”

## 执行合约

- 路由完成后，准确执行目标技能的工作流程。
- 不要在此文件中复制目标逻辑。
- 将清单/索引/日志更新语义留给目标技能。

## 用户体验约定

- 使用`wiki-ingest` **文档/内容源**
- 使用 `wiki-history-ingest` **代理历史记录源**

示例：

-`/wiki-history-ingest claude`
-`/wiki-history-ingest codex`
-`/wiki-history-ingest hermes`
-`/wiki-history-ingest openclaw`
- `$wiki-history-ingest claude`（使用 `$skill` 调用的代理）
