---
name: writer-memory
description: 面向作家的 agentic 记忆系统 —— 跟踪人物、关系、场景与主题
argument-hint: "init|char|rel|scene|query|validate|synopsis|status|export [args]"
level: 7
---

# Writer Memory —— 面向作家的 Agentic 记忆系统

为中文创意写作者设计的持久化记忆系统，适合小说、剧本、漫画脚本、互动叙事和长篇连载工作流。

## 概览

Writer Memory 跨 Kimi 会话为虚构作品作家维持上下文。它跟踪：

- **人物**：情感弧线、态度、台词语调、语体等级
- **世界观**：背景、规则、氛围、约束
- **关系**：人物关系随时间的动态演化
- **场景**：分镜构成、叙述语调、情感标签
- **主题**：情感主题、作者意图

所有数据持久化在 `.writer-memory/memory.json`，便于 git 协作。

## 命令

| 命令 | 行为 |
|---------|--------|
| `/oh-my-kimi:writer-memory init <project-name>` | 初始化新项目记忆 |
| `/oh-my-kimi:writer-memory status` | 展示记忆概览（人物数、场景数等） |
| `/oh-my-kimi:writer-memory char add <name>` | 添加新人物 |
| `/oh-my-kimi:writer-memory char <name>` | 查看人物详情 |
| `/oh-my-kimi:writer-memory char update <name> <field> <value>` | 更新人物字段 |
| `/oh-my-kimi:writer-memory char list` | 列出所有人物 |
| `/oh-my-kimi:writer-memory rel add <char1> <char2> <type>` | 添加关系 |
| `/oh-my-kimi:writer-memory rel <char1> <char2>` | 查看关系 |
| `/oh-my-kimi:writer-memory rel update <char1> <char2> <event>` | 添加关系事件 |
| `/oh-my-kimi:writer-memory scene add <title>` | 添加新场景 |
| `/oh-my-kimi:writer-memory scene <id>` | 查看场景详情 |
| `/oh-my-kimi:writer-memory scene list` | 列出所有场景 |
| `/oh-my-kimi:writer-memory theme add <name>` | 添加主题 |
| `/oh-my-kimi:writer-memory world set <field> <value>` | 设置世界观属性 |
| `/oh-my-kimi:writer-memory query <question>` | 自然语言查询（中文优先） |
| `/oh-my-kimi:writer-memory validate <character> <dialogue>` | 检查台词是否符合人物语调 |
| `/oh-my-kimi:writer-memory synopsis` | 生成情感导向的故事梗概 |
| `/oh-my-kimi:writer-memory export` | 把完整记忆导出为可读 Markdown |
| `/oh-my-kimi:writer-memory backup` | 手动备份 |

## 记忆类型

### 人物记忆

跟踪一致刻画所必需的单个人物属性：

| 字段 | 中文名 | 描述 |
|-------|--------|-------------|
| `arc` | 情感弧线 | 情感旅程（例如“封闭 -> 动摇 -> 主动选择”） |
| `attitude` | 态度 | 当前对生活 / 他人的态度 |
| `tone` | 台词语调 | 台词风格（例如“克制”“直白”“回避”） |
| `speechLevel` | 语体等级 | 正式度与称呼习惯：口语、书面、敬称、亲昵称呼、混合 |
| `keywords` | 关键词 | 人物常用的特征词 / 短语 |
| `taboo` | 禁忌词 | 人物绝不说或通常回避的词 / 短语 |
| `emotional_baseline` | 情绪基线 | 默认情绪状态 |
| `triggers` | 触发点 | 引发情绪反应的触发点 |

**示例：**
```text
/oh-my-kimi:writer-memory char add 林澈
/oh-my-kimi:writer-memory char update 林澈 arc "封闭 -> 动摇 -> 主动选择"
/oh-my-kimi:writer-memory char update 林澈 tone "克制, 当下感强, 压抑情绪"
/oh-my-kimi:writer-memory char update 林澈 speechLevel "平实口语"
/oh-my-kimi:writer-memory char update 林澈 keywords "没事, 算了, 还好"
/oh-my-kimi:writer-memory char update 林澈 taboo "我爱你, 我想你"
```

### 世界观记忆

确立你故事所在的宇宙：

| 字段 | 中文名 | 描述 |
|-------|--------|-------------|
| `setting` | 背景 | 时间、地点、社会语境 |
| `rules` | 规则 | 世界如何运作（魔法体系、社会规范、技术限制等） |
| `atmosphere` | 氛围 | 整体情绪与基调 |
| `constraints` | 约束 | 这个世界里**不**可能发生的事 |
| `history` | 历史 | 相关背景故事 |

### 关系记忆

捕捉人物之间随时间变化的动态：

| 字段 | 描述 |
|-------|-------------|
| `type` | 基础关系：romantic、familial、friendship、rivalry、professional |
| `status` | 当前状态：budding、stable、strained、broken、healing |
| `power_dynamic` | 谁占主导（若有） |
| `events` | 关系改变的时间线 |
| `tension` | 当前未解决的冲突 |
| `intimacy_level` | 情感亲密度（1-10） |

**示例：**
```text
/oh-my-kimi:writer-memory rel add 林澈 许晗 romantic
/oh-my-kimi:writer-memory rel update 林澈 许晗 "第一次并肩避雨 - 林澈回避"
/oh-my-kimi:writer-memory rel update 林澈 许晗 "许晗告白被拒"
/oh-my-kimi:writer-memory rel update 林澈 许晗 "林澈主动留下纸条"
```

### 场景记忆

跟踪每个场景及其情感结构：

| 字段 | 中文名 | 描述 |
|-------|--------|-------------|
| `title` | 标题 | 场景标识 |
| `characters` | 出场人物 | 谁出场 |
| `location` | 地点 | 发生地点 |
| `cuts` | 分镜构成 | 逐镜拆解 |
| `narration_tone` | 叙述语调 | 叙述者的语调风格 |
| `emotional_tag` | 情感标签 | 主要情感（例如“心动+不安”） |
| `purpose` | 场景目的 | 该场景为何存在于故事中 |
| `before_after` | 前后变化 | 人物在此场景前后发生了什么变化 |

### 主题记忆

捕捉贯穿故事的深层意义：

| 字段 | 中文名 | 描述 |
|-------|--------|-------------|
| `name` | 名称 | 主题标识 |
| `expression` | 表达方式 | 主题如何呈现 |
| `scenes` | 相关场景 | 承载该主题的场景 |
| `character_links` | 人物连接 | 哪些人物承担这个主题 |
| `author_intent` | 作者意图 | 你想让读者感受到什么 |

## 故事梗概生成

`/synopsis` 命令用 5 个核心要素生成情感导向的摘要：

### 5 个核心要素

1. **主人公态度概述**
   - 主人公如何面对生活 / 爱 / 冲突
   - 核心情感立场
   - 示例：“林澈是一个为了避免失去而先选择放弃的人”

2. **核心关系结构**
   - 推动故事的中心动态
   - 权力失衡与张力
   - 示例：“主动靠近的人与习惯逃离的人之间的拉扯”

3. **情感主题**
   - 故事唤起的感受
   - 不是情节，而是情感真相
   - 示例：“不相信自己值得被爱的人，如何学会接受停留”

4. **类型期待 vs 真实情感对比**
   - 表层类型预期 vs 实际情感内容
   - 示例：“表面是都市爱情，内核是自我接纳”

5. **结尾情感余韵**
   - 故事结束后留下的感觉
   - 示例：“不完美但温暖的选择，带着迟来的安定”

## 人物校验

`/validate` 命令检查台词是否符合人物既定的声音。

### 检查项

| 检查项 | 描述 |
|-------|-------------|
| **语体等级** | 敬称 / 口语 / 书面语 / 亲昵称呼是否匹配？ |
| **语调匹配** | 情感基调是否合适？ |
| **关键词使用** | 是否用了人物特征词？ |
| **禁忌词违背** | 是否用了人物通常回避的词？ |
| **情绪范围** | 是否在人物情绪基线之内？ |
| **语境贴合** | 是否适合当下关系与场景？ |

### 校验结果

- **PASS**：台词与人物一致
- **WARN**：有轻微不一致，可能是有意为之
- **FAIL**：与既定声音明显偏离

**示例：**
```text
/oh-my-kimi:writer-memory validate 林澈 "我爱你，许晗。我真的很想你。"
```

输出：
```text
[FAIL] 林澈 validation failed:
- 禁忌词："我爱你" - 人物通常回避直接告白
- 禁忌词："我想你" - 人物习惯压抑思念表达
- 语调：对林澈的克制风格来说过于直白

建议替代表达：
- “你来了。”（最小限度承认）
- “外面下雨了。”（转向外部事实）
- “吃饭了吗？”（用实际关心表达情感）
```

## 上下文查询

针对记忆的自然语言查询，中文优先。

### 示例查询

```text
/oh-my-kimi:writer-memory query "林澈在这个场景里会怎么说？"
/oh-my-kimi:writer-memory query "顾然现在的情绪状态是什么？"
/oh-my-kimi:writer-memory query "许晗和林澈的关系推进到哪一步了？"
/oh-my-kimi:writer-memory query "这个场景的情绪氛围是什么？"
/oh-my-kimi:writer-memory query "林澈主动发消息合理吗？"
/oh-my-kimi:writer-memory query "许晗生气时的说话方式是什么？"
```

系统会从所有相关记忆类型中综合给出答案。

## 行为

1. **Init 时**：创建 `.writer-memory/memory.json`，含项目元数据与空集合
2. **自动备份**：修改前先备份到 `.writer-memory/backups/`
3. **中文优先**：情感词汇、台词校验与示例默认使用中文语境
4. **会话加载**：会话开始时加载记忆，立刻进入上下文
5. **Git 友好**：JSON 格式便于干净 diff 与协作

## 集成

### 与 oh-my-kimi Notepad 系统

Writer Memory 与 `.omk/notepad.md` 集成：

- 场景灵感可作为笔记记录
- 分析会话中获得的人物洞察被保留
- notepad 与记忆之间相互引用

### 与 Architect Agent

做复杂人物分析时：

```text
Agent(subagent_type="oh-my-kimi:architect",
     model="opus",
     prompt="分析林澈在所有场景中的情感弧线...")
```

### 人物校验管道

校验从以下来源拉取上下文：

- 人物记忆（语调、关键词、禁忌）
- 关系记忆（与对话对象的动态）
- 场景记忆（当前情感语境）
- 主题记忆（作者意图）

### 故事梗概生成器

梗概生成会聚合：

- 所有人物的弧线
- 关键关系事件
- 场景情感标签
- 主题表达

## 示例

### 完整工作流

```text
# 初始化项目
/oh-my-kimi:writer-memory init 春末

# 添加人物
/oh-my-kimi:writer-memory char add 林澈
/oh-my-kimi:writer-memory char update 林澈 arc "封闭 -> 动摇 -> 主动选择"
/oh-my-kimi:writer-memory char update 林澈 tone "克制, 当下感强"
/oh-my-kimi:writer-memory char update 林澈 speechLevel "平实口语"

/oh-my-kimi:writer-memory char add 许晗
/oh-my-kimi:writer-memory char update 许晗 arc "确信 -> 动摇 -> 等待"
/oh-my-kimi:writer-memory char update 许晗 tone "直接, 坦诚"
/oh-my-kimi:writer-memory char update 许晗 speechLevel "亲近口语"

# 建立关系
/oh-my-kimi:writer-memory rel add 林澈 许晗 romantic
/oh-my-kimi:writer-memory rel update 林澈 许晗 "第一次见面 - 许晗单方面心动"
/oh-my-kimi:writer-memory rel update 林澈 许晗 "林澈拒绝"
/oh-my-kimi:writer-memory rel update 林澈 许晗 "重逢 - 林澈内心动摇"

# 设定世界
/oh-my-kimi:writer-memory world set setting "上海, 当代, 二十多岁职场人"
/oh-my-kimi:writer-memory world set atmosphere "城市的疏离感里藏着细微暖意"

# 添加主题
/oh-my-kimi:writer-memory theme add "不轻易放弃的爱"
/oh-my-kimi:writer-memory theme add "自我保护的墙"

# 添加场景
/oh-my-kimi:writer-memory scene add "天台重逢"

# 写作时查询
/oh-my-kimi:writer-memory query "林澈在分别场景里应该用什么语调说话？"

# 校验台词
/oh-my-kimi:writer-memory validate 林澈 "许晗，我们到此为止吧。"

# 生成梗概
/oh-my-kimi:writer-memory synopsis

# 导出参考
/oh-my-kimi:writer-memory export
```

### 快速查看人物

```text
/oh-my-kimi:writer-memory char 林澈
```

输出：
```text
## 林澈

**情感弧线：** 封闭 -> 动摇 -> 主动选择
**态度：** 防御性强，现实主义
**台词语调：** 克制，当下感强
**语体等级：** 平实口语
**关键词：** 没事，算了，还好
**禁忌词：** 我爱你，我想你

**关系：**
- 许晗：romantic（亲密度：6/10，状态：healing）

**出现过的场景：** 天台重逢，咖啡馆对话，最后的选择
```

## 存储 Schema

```json
{
  "version": "1.0",
  "project": {
    "name": "春末",
    "genre": "都市爱情",
    "created": "2024-01-15T09:00:00Z",
    "lastModified": "2024-01-20T14:30:00Z"
  },
  "characters": {
    "林澈": {
      "arc": "封闭 -> 动摇 -> 主动选择",
      "attitude": "防御性强，现实主义",
      "tone": "克制，当下感强",
      "speechLevel": "平实口语",
      "keywords": ["没事", "算了", "还好"],
      "taboo": ["我爱你", "我想你"],
      "emotional_baseline": "平静的疏离",
      "triggers": ["提到过去", "承诺未来"]
    }
  },
  "world": {
    "setting": "上海, 当代, 二十多岁职场人",
    "rules": [],
    "atmosphere": "城市的疏离感里藏着细微暖意",
    "constraints": [],
    "history": ""
  },
  "relationships": [
    {
      "id": "rel_001",
      "from": "林澈",
      "to": "许晗",
      "type": "romantic",
      "dynamic": "许晗主动 -> 双方趋于平衡",
      "speechLevel": "亲近口语",
      "evolution": [
        { "timestamp": "...", "change": "第一次见面 - 许晗单方面心动", "catalyst": "偶然相遇" },
        { "timestamp": "...", "change": "林澈拒绝", "catalyst": "过去创伤" },
        { "timestamp": "...", "change": "重逢 - 林澈内心动摇", "catalyst": "天台重逢" }
      ],
      "notes": "林澈的不信任 vs 许晗的等待",
      "created": "..."
    }
  ],
  "scenes": [
    {
      "id": "scene-001",
      "title": "天台重逢",
      "characters": ["林澈", "许晗"],
      "location": "公司天台",
      "cuts": ["许晗先发现林澈", "林澈表情僵住", "短暂沉默", "许晗先开口"],
      "narration_tone": "冷静克制",
      "emotional_tag": "紧张+思念",
      "purpose": "呈现重逢的尴尬与未消失的情感",
      "before_after": "林澈：疏离 -> 动摇"
    }
  ],
  "themes": [
    {
      "name": "不轻易放弃的爱",
      "expression": "许晗始终如一的态度",
      "scenes": ["天台重逢", "最后告白"],
      "character_links": ["许晗"],
      "author_intent": "呈现不是占有而是信任的爱"
    }
  ],
  "synopsis": {
    "protagonist_attitude": "林澈是一个为了避免失去而先选择放弃的人",
    "relationship_structure": "等待的人与逃离的人之间的拉扯",
    "emotional_theme": "对自己是否值得被爱的怀疑",
    "genre_contrast": "表面是都市爱情，内核是自我接纳",
    "ending_aftertaste": "不完美但温暖的选择"
  }
}
```

## 文件结构

```text
.writer-memory/
├── memory.json          # 主记忆文件
├── backups/             # 改动前的自动备份
│   ├── memory-2024-01-15-090000.json
│   └── memory-2024-01-20-143000.json
└── exports/             # Markdown 导出
    └── export-2024-01-20.md
```

## 给作家的建议

1. **从人物开始**：先把人物记忆建好，再建场景
2. **关键场景后更新关系**：积极跟踪演化
3. **写作时随手用 validate**：尽早抓住声音不一致
4. **难写的场景前先 query**：让系统提醒你相关上下文
5. **定期生成梗概**：检查主题一致性
6. **重大改动前备份**：在显著故事转向前用 `/backup`

## 排错

**记忆没加载？**

- 检查 `.writer-memory/memory.json` 是否存在
- 检查 JSON 语法是否有效
- 跑 `/oh-my-kimi:writer-memory status` 诊断

**校验太严格？**

- 检查 taboo 列表是否有误录
- 考虑人物是否在成长（弧线推进）
- 戏剧时刻里有意打破模式是合理的

**query 找不到上下文？**

- 确保相关数据已在记忆里
- 试更具体的查询
- 检查人物名是否完全一致
