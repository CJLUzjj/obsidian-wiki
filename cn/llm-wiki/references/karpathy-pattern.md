> 原 Skill 位置：`.skills/llm-wiki/references/karpathy-pattern.md`

# Karpathy 的 LLM Wiki 模式 — 原始参考

来源：https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

## 核心洞察

"Wiki 是一个持久的、复合的工件。知识被编译一次，然后保持最新，而不是在每次查询时重新推导。"

人类策划来源并提出问题；LLM 维护知识系统。Obsidian 成为 IDE，LLM 成为程序员，Wiki 成为代码库。

## 为什么这比 RAG 更好

传统 RAG 在每次查询时重新发现知识——它搜索原始来源，提取相关块，并从头开始合成答案。LLM Wiki 将知识编译一次到维护的页面中，因此查询会命中预先合成的、交叉引用的内容。

## 关键操作

| 操作 | 功能 | 使用时机 |
|---|---|---|
| **Ingest** | 读取新来源，提取关键信息，更新 10-15 个 wiki 页面，维护一致性 | 当新文档到达时 |
| **Query** | 针对编译的 wiki 回答问题并提供引用 | 当用户提出问题时 |
| **Lint** | 识别矛盾、孤立页面、陈旧声明、缺失的交叉引用 | 定期维护 |

## 推荐工具

- **Obsidian** — 用于浏览和探索 wiki 的 IDE
- **Web Clipper** — 用于将文章转换为 markdown 的浏览器扩展
- **Marp** — 基于 markdown 的幻灯片，来自 wiki 内容
- **Dataview** — 用于查询页面元数据的 Obsidian 插件
- **qmd** — 具有 BM25/向量混合搜索的本地搜索引擎

## 应用

- 个人追踪（目标、心理学、自我改进）
- 研究（在数周/数月内建立全面理解）
- 书籍注释（包含人物、主题、情节连接的伴随 wiki）
- 团队/业务（来自 Slack 线程、会议记录的 wiki）
- 尽职调查、竞争分析、旅行规划

## 值得了解的社区扩展

- **Provenance tracking** — 记录哪些源文件产生了每个声明，通过内容哈希检测陈旧性
- **Hierarchical inheritance** — 父子页面关系而不是平面索引
- **Decision records** — 捕获 wiki 为什么演变，而不仅仅是改变了什么
- **Two-tier LLMs** — 本地模型用于敏感数据，云用于其余部分
- **Graph databases** — 类型化本体而不是 markdown 链接
