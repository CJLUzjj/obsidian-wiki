---
name: wiki-rebuild
description: >
  归档现有的 wiki 知识并从头开始重建，或从以前的归档中恢复。
  当用户想要重新开始、从所有来源重建 wiki、存档当前内容时，请使用此技能
  进行重大更改之前的知识，或恢复旧版本。触发“重建维基”，
  “重新开始”、“存档并重建”、“从存档恢复”、“核弹并重新铺开”、“干净重建”。
  当 wiki 偏离来源太远并且增量修复无法解决问题时也可以使用。
---

> 原 Skill 位置：`.skills/wiki-rebuild/SKILL.md`


# Wiki 重建 — 存档、重建、恢复

您正在维基上执行破坏性操作。始终先存档，并在继续之前始终与用户确认。

## 开始之前

1.读取`.env`得到`OBSIDIAN_VAULT_PATH`
2. 读取`.manifest.json`了解当前状态
3. **确认用户意图。** 该技能支持三种模式：
   - **仅存档** — 快照当前 wiki，无需重建
   - **存档 + 重建** — 快照，然后从头开始重新处理所有源
   - **恢复** — 恢复以前的存档

## 档案系统

档案直播于`$OBSIDIAN_VAULT_PATH/_archives/`。每个存档都是一个带时间戳的目录，其中包含当时 wiki 状态的完整副本。```
$OBSIDIAN_VAULT_PATH/
├── _archives/
│   ├── 2026-04-01T10-30-00Z/
│   │   ├── archive-meta.json
│   │   ├── concepts/
│   │   ├── entities/
│   │   ├── skills/
│   │   ├── references/
│   │   ├── synthesis/
│   │   ├── journal/
│   │   ├── projects/
│   │   ├── index.md
│   │   ├── log.md
│   │   └── .manifest.json
│   └── 2026-03-15T08-00-00Z/
│       └── ...
├── concepts/          ← live wiki
├── entities/
└── ...
```
### 存档-meta.json```json
{
  "archived_at": "2026-04-06T10:30:00Z",
  "reason": "rebuild",
  "total_pages": 87,
  "total_sources": 42,
  "total_projects": 6,
  "vault_path": "/Users/name/Knowledge",
  "manifest_snapshot": ".manifest.json"
}
```
## 模式 1：仅存档

当用户想要快照当前状态而不重建时。

### 步骤：

1.创建存档目录：`_archives/YYYY-MM-DDTHH-MM-SSZ/`
2. 将所有类别目录`index.md`、`log.md`、`.manifest.json` 和`projects/` 复制到存档中
3.写`archive-meta.json`，原因`"snapshot"`
4. 附加到`log.md`：
   ````
   - [时间戳] 归档原因=“快照”页面= 87目的地=“_archives / 2026-04-06T10-30-00Z”
   ````
5. 报告：“已存档 87 页。当前 wiki 未受影响。”

## 模式 2：存档 + 重建

当用户想要重新开始时。这是完整的序列：

### 第 1 步：存档当前状态

与上面的模式 1 相同，但有原因`"rebuild"`。

### 第 2 步：清除实时 wiki

删除类别目录（`concepts/`、`entities/`、`skills/` 等）和`projects/` 目录中的所有内容。保留：
-`_archives/`（显然）
- `.obsidian/`（黑曜石配置）
- `.env`（如果存在于保险库中）

将`index.md`重置为空模板。仅使用重建条目重置`log.md`。删除`.manifest.json`（它将在摄取过程中重新创建）。

### 第 3 步：重建

告诉用户保管库已清除并准备好完全重新摄取。他们现在可以运行：

1. `wiki-status` — 将所有来源视为“新”
2. `claude-history-ingest` — 重新处理克劳德历史
3. `codex-history-ingest` — 重新处理 Codex 会话历史记录
4. `wiki-ingest` — 重新处理文档
5. `data-ingest` — 重新处理任何其他数据

其中每一个都会在运行时重建清单。

**重要提示：** 不要自己自动运行摄取。用户应该选择重新摄取什么以及以什么顺序。有些来源可能不再相关。

### 步骤 4：记录重建

附加到`log.md`：```
- [TIMESTAMP] REBUILD archived_to="_archives/2026-04-06T10-30-00Z" previous_pages=87
```
## 模式 3：从存档恢复

当用户想要返回到之前的状态时。

### 第 1 步：列出可用档案

读取`_archives/`目录。对于每个档案，请阅读 `archive-meta.json` 并呈现：```markdown
## Available Archives

| Date | Reason | Pages | Sources |
|---|---|---|---|
| 2026-04-06 10:30 | rebuild | 87 | 42 |
| 2026-03-15 08:00 | snapshot | 65 | 31 |
```
### 步骤 2：确认要恢复的存档

询问用户他们想要哪个存档。警告他们恢复将覆盖当前的实时 wiki。

### 步骤 3：首先存档当前状态

在恢复之前，请存档当前状态（原因：`"pre-restore"`），这样就不会丢失任何内容。

### 第 4 步：恢复

1. 清除实时wiki（同模式2，步骤2）
2. 将所选存档中的所有内容复制回实时 wiki 目录中
3. 从存档中恢复`index.md`、`log.md` 和`.manifest.json`
4. 附加到`log.md`：
   ````
   - [时间戳] 恢复自=“_archives/2026-03-15T08-00-00Z”pages_restored=65
   ````

### 第 5 步：报告

告诉用户恢复了什么，并建议运行 `wiki-lint` 以检查恢复状态是否存在任何问题。

## 安全规则

1. **始终在破坏性操作之前进行存档。** 无一例外。
2. **在清除实时维基之前，请务必与用户确认**。
3. **永远不要删除档案**，除非用户明确要求。档案是廉价的保险。
4. **`.obsidian/` 目录是神圣的。** 在存档/重建/恢复期间切勿触摸它 - 它包含用户的 Obsidian 设置、插件和主题。
5. 如果重建过程中出现问题，存档就在那里。告诉用户他们可以恢复。
