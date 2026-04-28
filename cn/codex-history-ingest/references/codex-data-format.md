> 原 Skill 位置：`.skills/codex-history-ingest/references/codex-data-format.md`

# Codex 数据格式 — 详细参考

本参考描述了 Codex 本地历史摄取的实际观察到的结构。

## 根目录布局

`~/.codex/` 通常包含：

- `sessions/YYYY/MM/DD/rollout-*.jsonl` — 主要结构化会话日志
- `archived_sessions/` — 存档的 rollout
- `session_index.jsonl` — 会话 id/名称/更新索引
- `history.jsonl` — 转录历史（取决于配置）
- `config.toml` — 历史持久化控制

## 会话索引

`~/.codex/session_index.jsonl` 条目是每行一个 JSON 对象，通常为：

```json
{"id":"<thread-id>","thread_name":"<title>","updated_at":"<timestamp>"}
```

将其用作追加/完整模式增量的库存主干。

## Rollout JSONL

`rollout-*.jsonl` 文件是具有信封字段的事件流：

```json
{
  "timestamp": "2026-04-12T09:40:02.337Z",
  "type": "session_meta|turn_context|event_msg|response_item",
  "payload": { "...": "..." }
}
```

常见的 `type` 值：

- `session_meta` — 运行元数据（id、cwd、model/provider 等）
- `turn_context` — 轮次范围的上下文信封
- `event_msg` — 运行时事件（任务生命周期、token/计费、工具调用标记）
- `response_item` — 模型响应项（消息、工具调用、推理块）

### 典型的 payload 子类型

观察到的示例包括：

- `event_msg.payload.type`: `task_started`、`user_message`、`agent_message`、`mcp_tool_call_end`、`exec_command_end`、`token_count`
- `response_item.payload.type`: `message`、`function_call`、`function_call_output`、`reasoning`

## 提取策略

### 保留

- 来自用户消息记录的用户意图
- 来自助手消息记录的助手结论/决策
- 编码可重用知识的高信号工具输出

### 跳过

- 纯遥测（`token_count`、低级管道事件）
- 内部推理跟踪，除非用户明确要求保留
- 没有持久洞察的冗长执行转储

## 隐私说明

Rollout 可能包含敏感数据：

- 注入的指令层
- 工具输入/输出
- 命令输出中的潜在机密

始终对机密进行编辑，并总结而不是复制原始转录内容。

## 配置交互

`~/.codex/config.toml` 影响摄取完整性的键：

- `history.persistence = "save-all" | "none"`
- `history.max_bytes = <int>`（截断/压缩上限）

`codex exec --ephemeral` 运行可能不会持久化 rollout 文件。
