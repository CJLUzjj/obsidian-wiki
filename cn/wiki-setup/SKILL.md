---
name: wiki-setup
description: >
  使用正确的结构、特殊文件和配置初始化新的 Obsidian wiki 库。
  当用户想要从头开始建立一个新的 wiki、初始化保管库结构时使用此技能，
  创建 .env 文件，或者说“设置我的 wiki”、“初始化黑曜石”、“创建一个新的保管库”等内容
  “开始使用维基”。当用户需要重新配置其现有保管库或
  修复损坏的设置。
---

> 原 Skill 位置：`.skills/wiki-setup/SKILL.md`


# Obsidian 设置 — Vault 初始化

您正在设置一个新的黑曜石维基保管库（或修复现有的保管库）。

## 步骤 1：创建 .env

如果`.env`不存在，则从`.env.example`创建它。询问用户：

1. **金库应该住在哪里？** → `OBSIDIAN_VAULT_PATH`
   - 默认：`~/Documents/obsidian-wiki-vault`
   - 必须是绝对路径（扩展后）

2. **你的源文件在哪里？** → `OBSIDIAN_SOURCES_DIR`
   - 可以是多个路径，以逗号分隔
   - 默认：`~/Documents`

3. **想要导入克劳德历史记录吗？** → `CLAUDE_HISTORY_PATH`
   - 默认：自动发现`~/.claude`
   - 如果克劳德数据在其他地方，则明确设置

4. **是否已安装 QMD？** → `QMD_WIKI_COLLECTION` / `QMD_PAPERS_COLLECTION`
   - 可选。在`wiki-query` 中启用语义搜索，并在`wiki-ingest` 中启用源发现。
   - 如果不确定，请暂时跳过 - 两项技能都会自动回落到`Grep`。
   - 安装说明：请参阅`.env.example`（QMD 部分）。

## 步骤 2：创建 Vault 目录结构```bash
mkdir -p "$OBSIDIAN_VAULT_PATH"/{concepts,entities,skills,references,synthesis,journal,projects,_archives,_raw,.obsidian}
```
- `.obsidian/` — Obsidian 自己的配置。创建金库识别。
- `projects/` — 每个项目的知识（在摄取期间填充）。
- `_archives/` — 存储用于重建/恢复操作的 wiki 快照。
- `_raw/` — 未处理草稿的暂存区。在这里留下粗略的笔记； `wiki-ingest` 会将它们提升到正确的 wiki 页面并删除原始页面。

## 步骤 3：创建特殊文件

###索引.md```markdown
---
title: Wiki Index
---

# Wiki Index

*This index is automatically maintained. Last updated: TIMESTAMP*

## Concepts

*No pages yet. Use `wiki-ingest` to add your first source.*

## Entities

## Skills

## References

## Synthesis

## Journal
```
### 日志.md```markdown
---
title: Wiki Log
---

# Wiki Log

- [TIMESTAMP] INIT vault_path="OBSIDIAN_VAULT_PATH" categories=concepts,entities,skills,references,synthesis,journal
```
### 热.md```markdown
---
title: Hot Cache
updated: TIMESTAMP
---

# Hot Cache

*A ~500-word semantic snapshot of recent activity. Updated after every major write operation.*

## Recent Activity

- [TIMESTAMP] INIT — vault created at OBSIDIAN_VAULT_PATH

## Active Threads

*None yet — start ingesting sources to populate.*

## Key Takeaways

*None yet.*

## Flagged Contradictions

*None yet.*
```
## 步骤 4：创建 .obsidian 配置

创建最小的黑曜石配置以获得良好的开箱即用体验：

### .obsidian/app.json```json
{
  "strictLineBreaks": false,
  "showFrontmatter": false,
  "defaultViewMode": "preview",
  "livePreview": true
}
```
### .obsidian/appearance.json```json
{
  "baseFontSize": 16
}
```
## 步骤 5：推荐黑曜石插件

告诉用户这些推荐的社区插件（它们是手动安装的）：

1. **Dataview** — 查询页面元数据，创建动态表。对于维基来说必不可少。
2. **图形分析** — 用于探索连接的增强图形视图。
3. **Templater** — 如果他们想使用模板手动创建页面。
4. **Obsidian Git** — 自动将保管库备份到 git 存储库。

## 第 6 步：验证设置

运行快速健全性检查：
- [ ] Vault 目录存在：`concepts/`、`entities/`、`skills/`、`references/`、`synthesis/`、`journal/`、`projects/`、`_archives/`、`_raw/`
- [ ] `index.md` 存在于保管库根目录
- [ ] `log.md` 存在于保管库根目录
- [ ] `hot.md` 存在于保管库根目录
- [ ] `.env` 已设置 `OBSIDIAN_VAULT_PATH`
- [ ] `.obsidian/` 目录存在
- [ ] 源目录（如果配置）存在且可读

报告结果并告诉用户他们现在可以：
1.在Obsidian中打开Vault（文件→打开Vault→选择目录）
2. 运行 `wiki-status` 查看可摄取的内容
3. 运行 `wiki-ingest` 添加第一个源
4.运行`claude-history-ingest`来挖掘他们的Claude对话
5.运行`codex-history-ingest`来挖掘他们的Codex会话（如果他们使用Codex）
6. 随时再次运行 `wiki-status` 以检查增量
