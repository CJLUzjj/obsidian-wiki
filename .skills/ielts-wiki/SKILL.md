---
name: ielts-wiki
description: 在 Obsidian 中维护 IELTS 学习 wiki，包括来源材料、词汇、语法、示例、错误、练习题、学习日志和个性化学习计划。
---

# IELTS Wiki 技能

此技能用于在 obsidian-wiki 工作流之上维护一个 IELTS 学习 wiki。

这个仓库不是简单的笔记集合。它是一个结构化学习系统，用于连接：

- 原始 IELTS 材料
- 词汇
- 搭配
- 语法模式
- 示例
- 题型
- 错误
- 学习日志
- 练习题
- 学习计划

目标是将原始学习材料转化为互相连接的 Obsidian 知识图谱，以支持个性化学习规划和练习生成。

---

## 1. 核心原则

### 1.1 Obsidian 是查看器

Obsidian 用于浏览、搜索和可视化知识图谱。

使用 Obsidian 原生 Markdown 链接：

- `[[vocabulary note]]`
- `[[grammar note]]`
- `[[source material]]`
- `[[mistake note]]`
- `[[practice page]]`

### 1.2 AI agent 是维护者

AI agent 应该：

- 摄取新学习材料
- 创建和更新笔记
- 维护 wikilinks
- 更新元数据
- 跟踪错误
- 创建学习计划
- 生成练习任务
- 更新学习日志

### 1.3 来源必须可追溯

每个重要词汇项、语法点、示例和错误都应链接回原始来源材料。

不要创建彼此断开的笔记。

### 1.4 错误比笔记更重要

错误笔记是个性化规划的主要信号。

在创建学习计划或练习题时，优先考虑：

1. 未解决错误
2. 重复错误
3. 高严重度错误
4. 逾期词汇复习
5. 薄弱语法页面
6. 薄弱 IELTS 题型

---

## 2. 核心文件与目录

不要重命名或删除这些 obsidian-wiki 核心文件：

- `index.md`
- `log.md`
- `hot.md`
- `.manifest.json`
- `_raw/`

这些文件由更大的 obsidian-wiki 工作流使用。

---

## 3. 目录映射

使用以下仓库结构。

### 3.1 obsidian-wiki 核心目录

- `references/ielts/`  
  阅读文章、听力转录、作文、口语转录和官方题目的来源摘要。

- `concepts/grammar/`  
  语法概念和句式模式。

- `concepts/question-types/`  
  IELTS 题型，例如 Matching Headings、True False Not Given、Map Labelling、Task 2 Opinion Essay。

- `concepts/topics/`  
  IELTS 主题与观点库，例如 education、environment、technology、health、work、cities、transport。

- `skills/reading/`  
  阅读策略和方法。

- `skills/listening/`  
  听力策略和方法。

- `skills/writing/`  
  写作策略、文章结构、段落模式和评分标准。

- `skills/speaking/`  
  口语策略、Part 1/2/3 回答框架、流利度方法。

- `synthesis/study-plans/`  
  周计划、月计划、冲刺计划、复盘报告。

- `journal/study-log/`  
  每日学习记录。

### 3.2 IELTS 专用目录

- `vocabulary/`  
  词汇、短语、搭配、学术表达。

- `examples/`  
  来源示例、写作句子、口语答案、语法示例。

- `mistakes/`  
  学习者错误与根因分析。

- `practice/`  
  AI 生成练习与答案复盘。

---

## 4. 摄取流程

当从 `_raw/` 摄取新材料时，使用此流程。

材料可能包括：

- 阅读文章
- 听力转录
- 写作作文
- 口语转录
- 词汇表
- 题目复盘
- 答题纸
- 模考结果

### 4.1 摄取前

摄取前检查：

- `index.md`
- `hot.md`
- `log.md`
- `.manifest.json`
- 已有相关来源页面
- 已有词汇页面
- 已有语法页面
- 已有错误页面

避免创建重复笔记。

### 4.2 来源页面创建

对于每个来源材料，在以下路径创建或更新一个页面：

`references/ielts/`

来源页面应包含：

- 标题
- 材料类型
- 技能领域
- 主题
- 摘要
- 提取词汇
- 有用搭配
- 语法示例
- 题型
- 有用的写作或口语思路
- 相关错误
- 相关练习页面

### 4.3 词汇提取

在以下路径创建或更新词汇笔记：

`vocabulary/`

只为对 IELTS 有用的词或短语创建词汇笔记。

应创建词汇笔记的对象：

- 重复出现的词
- IELTS 学术词
- 主题相关词
- 有用搭配
- 学习者做错的词
- 对写作或口语有用的词
- 出现在多个来源中的词

不要为每个琐碎词都创建笔记。

### 4.4 语法提取

在以下路径创建或更新语法笔记：

`concepts/grammar/`

应为以下内容创建语法笔记：

- 来源材料中出现的模式
- 对 IELTS 写作有用的模式
- 对 IELTS 口语有用的模式
- 学习者错误使用的句法结构
- 影响阅读理解的结构

### 4.5 题型提取

在以下路径创建或更新题型笔记：

`concepts/question-types/`

示例：

- `Matching Headings`
- `True False Not Given`
- `Yes No Not Given`
- `Multiple Choice`
- `Sentence Completion`
- `Map Labelling`
- `Task 1 Line Graph`
- `Task 2 Opinion Essay`
- `Speaking Part 2 Cue Card`

### 4.6 错误提取

在以下路径创建错误笔记：

`mistakes/`

当材料包含以下内容时创建错误笔记：

- 错误答案
- 词汇误解
- 语法错误
- 作文问题
- 口语流利度问题
- 发音问题
- 时间管理问题
- 重复策略错误

错误笔记应具体且可执行。

---

## 5. 页面模板

创建页面时使用以下结构。

---

## 5.1 来源页面模板

目录：

`references/ielts/`

Frontmatter 格式：

    ---
    title:
    type: source
    category: references/ielts
    skill:
    source_type:
    topic: []
    difficulty:
    date_ingested:
    sources: []
    tags:
      - ielts/source
    summary:
    ---

正文格式：

    # Title

    ## Summary

    Briefly summarize the source material.

    ## IELTS Relevance

    Explain why this material is useful for IELTS.

    ## Extracted Vocabulary

    - [[word or phrase]]

    ## Useful Collocations

    - collocation one
    - collocation two

    ## Grammar Examples

    - [[grammar pattern]]

    ## Question Types

    - [[question type]]

    ## Useful Examples

    - [[example note]]

    ## Related Mistakes

    - [[mistake note]]

    ## Related Practice

    - [[practice page]]

---

## 5.2 词汇页面模板

目录：

`vocabulary/`

Frontmatter 格式：

    ---
    title:
    type: vocabulary
    category: vocabulary
    part_of_speech:
    status: learning
    review_stage: 0
    last_reviewed:
    next_review:
    sources: []
    tags:
      - ielts/vocabulary
    summary:
    ---

正文格式：

    # Word or Phrase

    ## Meaning in IELTS Context

    Explain the meaning in simple English and, when useful, in Chinese.

    ## Common Collocations

    - collocation one
    - collocation two
    - collocation three

    ## Source Examples

    - From [[source page]]:
      - Example sentence.

    ## IELTS Writing Usage

    Show how this word or phrase can be used in Task 1 or Task 2.

    ## IELTS Speaking Usage

    Show how this word or phrase can be used in Speaking Part 1, 2, or 3.

    ## Related Notes

    - [[related vocabulary]]
    - [[related topic]]
    - [[related grammar]]

    ## Related Mistakes

    - [[mistake note]]

    ## Review

    - Status:
    - Last reviewed:
    - Next review:

---

## 5.3 语法页面模板

目录：

`concepts/grammar/`

Frontmatter 格式：

    ---
    title:
    type: grammar
    category: concepts/grammar
    status: weak
    sources: []
    tags:
      - ielts/grammar
    summary:
    ---

正文格式：

    # Grammar Pattern

    ## Pattern

    Explain the structure.

    ## IELTS Relevance

    Explain how this helps with IELTS reading, writing, listening, or speaking.

    ## Source Examples

    - From [[source page]]:
      - Example sentence.

    ## Learner Mistakes

    - [[mistake note]]

    ## Correct Examples

    - Correct example one.
    - Correct example two.

    ## Practice Prompts

    - Prompt one.
    - Prompt two.

    ## Related Notes

    - [[related vocabulary]]
    - [[related question type]]
    - [[related skill]]

---

## 5.4 题型页面模板

目录：

`concepts/question-types/`

Frontmatter 格式：

    ---
    title:
    type: question-type
    category: concepts/question-types
    skill:
    status:
    sources: []
    tags:
      - ielts/question-type
    summary:
    ---

正文格式：

    # Question Type

    ## What It Tests

    Explain what this IELTS question type tests.

    ## Common Traps

    - trap one
    - trap two

    ## Strategy

    Step-by-step strategy.

    ## Related Mistakes

    - [[mistake note]]

    ## Related Practice

    - [[practice page]]

    ## Related Skills

    - [[reading skill]]
    - [[listening skill]]
    - [[writing skill]]
    - [[speaking skill]]

---

## 5.5 错误页面模板

目录：

`mistakes/`

Frontmatter 格式：

    ---
    title:
    type: mistake
    category: mistakes
    date:
    skill:
    question_type:
    severity:
    status: unresolved
    sources: []
    tags:
      - ielts/mistake
    summary:
    ---

正文格式：

    # Mistake Title

    ## What I Got Wrong

    Describe the mistake clearly.

    ## Correct Answer or Correct Version

    Provide the correct answer, sentence, reasoning, or method.

    ## Root Cause

    Identify the real cause.

    Possible root causes:

    - vocabulary gap
    - grammar weakness
    - misunderstood question
    - weak paraphrase recognition
    - poor time management
    - weak topic knowledge
    - careless reading
    - listening distraction
    - writing structure problem
    - speaking fluency problem

    ## Related Vocabulary

    - [[vocabulary note]]

    ## Related Grammar

    - [[grammar note]]

    ## Related Source

    - [[source page]]

    ## Fix

    Describe what the learner should do next.

    ## Follow-up Task

    Add a concrete review or practice task.

    ## Status

    unresolved | reviewing | resolved

---

## 5.6 示例页面模板

目录：

`examples/`

Frontmatter 格式：

    ---
    title:
    type: example
    category: examples
    skill:
    source:
    related_vocabulary: []
    related_grammar: []
    tags:
      - ielts/example
    summary:
    ---

正文格式：

    # Example Title

    ## Example

    Write the example sentence, phrase, paragraph, or speaking answer.

    ## Why It Is Useful

    Explain why this example is useful for IELTS.

    ## Related Vocabulary

    - [[vocabulary note]]

    ## Related Grammar

    - [[grammar note]]

    ## Related Source

    - [[source page]]

    ## Reuse

    Explain how the learner can reuse this in IELTS writing or speaking.

---

## 5.7 学习日志模板

目录：

`journal/study-log/`

Frontmatter 格式：

    ---
    title: Study Log -
    type: study-log
    category: journal/study-log
    date:
    time_spent_min:
    skills:
      reading:
      listening:
      writing:
      speaking:
    tags:
      - ielts/study-log
    summary:
    ---

正文格式：

    # Study Log - Date

    ## What I Studied

    - [[source page]]
    - [[vocabulary note]]
    - [[grammar note]]

    ## Practice Completed

    - [[practice page]]

    ## Mistakes Created or Updated

    - [[mistake note]]

    ## Reflection

    Brief reflection on progress, difficulty, focus, or energy.

    ## Next Actions

    - action one
    - action two

---

## 5.8 练习页面模板

目录：

`practice/`

Frontmatter 格式：

    ---
    title:
    type: practice
    category: practice
    date:
    skill:
    focus:
    status: assigned
    related_mistakes: []
    related_vocabulary: []
    related_grammar: []
    tags:
      - ielts/practice
    summary:
    ---

正文格式：

    # Practice Title

    ## Focus

    Explain what this practice targets.

    ## Related Notes

    - [[mistake note]]
    - [[vocabulary note]]
    - [[grammar note]]

    ## Questions

    Add practice questions here.

    ## My Answers

    Add learner answers here.

    ## Review

    Add grading, corrections, explanations, and follow-up tasks.

---

## 5.9 学习计划模板

目录：

`synthesis/study-plans/`

Frontmatter 格式：

    ---
    title:
    type: study-plan
    category: synthesis/study-plans
    start_date:
    end_date:
    status: active
    target_band:
    focus_skills: []
    tags:
      - ielts/study-plan
    summary:
    ---

正文格式：

    # Study Plan

    ## Current Diagnosis

    Summarize the learner's current strengths and weaknesses.

    ## Priorities

    List the highest-priority areas.

    ## Weekly Goals

    - goal one
    - goal two
    - goal three

    ## Daily Plan

    ### Day 1

    - task one
    - task two

    ### Day 2

    - task one
    - task two

    ## Practice Pages

    - [[practice page]]

    ## Review Criteria

    Explain how progress will be checked.

---

## 6. 规划规则

当被要求创建学习计划时，读取并使用：

1. `journal/study-log/` 中近期页面
2. `mistakes/` 中未解决页面
3. `vocabulary/` 中 `next_review` 逾期页面
4. `concepts/grammar/` 中 `status: weak` 的页面
5. 重复错误的题型页面
6. 学习者目标分数
7. 学习者考试日期（如果可用）

学习计划必须包含：

- 当前诊断
- 最高优先级
- 每日任务
- 复习任务
- 练习任务
- 相关笔记链接
- 可衡量目标

学习计划保存到：

`synthesis/study-plans/`

---

## 7. 练习生成规则

生成练习题时：

1. 基于未解决错误。
2. 复用 `vocabulary/` 中词汇。
3. 复用 `concepts/grammar/` 中语法。
4. 复用 `concepts/topics/` 中主题。
5. 每道题链接相关笔记。
6. 生成的练习页面保存到 `practice/`。
7. 学习者作答后，更新：
   - 相关错误页面
   - 词汇复习阶段
   - 语法状态
   - 当天学习日志

如果 wiki 已经包含足够弱项信号，不要随机生成练习。

---

## 8. 复盘规则

复盘学习者答案时：

1. 给答案评分。
2. 解释每个错误答案为什么错。
3. 识别根因。
4. 创建或更新错误页面。
5. 如果词汇导致错误，更新词汇页面。
6. 如果语法导致错误，更新语法页面。
7. 更新相关练习页面。
8. 更新当天学习日志。
9. 建议下一项具体任务。

---

## 9. 词汇复习规则

使用简单的复习阶段系统：

- `review_stage: 0` 表示新词。
- `review_stage: 1` 表示复习过一次。
- `review_stage: 2` 表示部分熟悉。
- `review_stage: 3` 表示大体熟悉。
- `review_stage: 4` 表示稳定。
- `review_stage: 5` 表示掌握。

当学习者回答正确时，阶段加 1。

当学习者在某词上犯错时，按严重度将阶段减 1 或保持不变。

始终更新：

- `last_reviewed`
- `next_review`
- 相关错误

建议复习间隔：

- stage 0: 次日
- stage 1: 3 天后
- stage 2: 7 天后
- stage 3: 14 天后
- stage 4: 30 天后
- stage 5: 仅在该词再次出现在错误中时复习

---

## 10. 知识图谱规则

始终创建有价值的 wikilinks。

重要链接模式：

- 来源页面链接词汇页面，
- 来源页面链接语法页面，
- 来源页面链接题型页面，
- 词汇页面回链来源页面，
- 语法页面回链来源页面，
- 错误页面链接来源、词汇、语法和题型，
- 练习页面链接错误和薄弱笔记，
- 学习计划链接练习页面和薄弱区域，
- 学习日志链接所有学习材料。

理想图谱应支持如下路径：

- `[[source material]]` -> `[[vocabulary]]` -> `[[mistake]]` -> `[[practice]]` -> `[[study plan]]`
- `[[source material]]` -> `[[grammar pattern]]` -> `[[example]]` -> `[[writing skill]]`
- `[[mistake]]` -> `[[question type]]` -> `[[reading strategy]]`

避免孤立笔记。

---

## 11. 索引与日志更新

任何重要更新后，更新：

- `index.md`
- `hot.md`
- `log.md`
- `.manifest.json`（当涉及来源摄取时）

`index.md` 应帮助学习者导航主要区域。

`hot.md` 应包含简短的当前上下文摘要，包括：

- 当前重点
- 近期来源
- 活跃错误
- 即将复习
- 当前学习计划

`log.md` 应记录重要维护操作。

---

## 12. 质量规则

完成任务前检查：

- 每个新页面是否都有 frontmatter？
- 每个重要页面是否都有 summary？
- 每个词汇笔记是否至少链接一个来源？
- 每个错误笔记是否包含根因？
- 每个练习页面是否链接了其目标弱项？
- 每个学习计划是否链接了实际练习任务？
- 更新是否避免了重复页面？
- 更新是否保留了 obsidian-wiki 核心文件？

---

## 13. 默认命令

按如下方式理解这些用户请求。

### "Ingest my new IELTS materials"

读取 `_raw/`，然后创建或更新：

- 来源页面
- 词汇页面
- 语法页面
- 题型页面
- 示例页面
- 错误页面
- index
- hot 上下文
- log

### "Make me a study plan"

读取：

- 近期学习日志
- 未解决错误
- 薄弱词汇
- 薄弱语法
- 薄弱题型

然后在以下路径创建或更新学习计划：

`synthesis/study-plans/`

### "Generate practice"

在以下路径创建练习页面：

`practice/`

其依据：

- 未解决错误
- 逾期词汇
- 薄弱语法
- 重复题型错误

### "Review my answers"

评分答案并解释错误，更新：

- 练习页面
- 错误页面
- 词汇复习阶段
- 语法状态
- 学习日志

### "Audit my IELTS wiki"

检查：

- 断链
- 孤立笔记
- 缺失 frontmatter
- 无来源词汇
- 无后续任务的错误
- 无链接活动的学习日志
- 无链接练习页面的学习计划
