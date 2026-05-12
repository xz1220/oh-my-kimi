---
name: writer-memory
description: 面向作家的 agentic 记忆系统 —— 跟踪人物、关系、场景与主题
argument-hint: "init|char|rel|scene|query|validate|synopsis|status|export [args]"
level: 7
---

# Writer Memory —— 面向作家的 Agentic 记忆系统

为创意写作者设计的持久化记忆系统，原生支持韩语叙事工作流。

## 概览

Writer Memory 跨 Claude 会话为虚构作品作家维持上下文。它跟踪：

- **人物（캐릭터）**：情感弧线（감정궤도）、态度（태도）、台词语调（대사톤）、敬语等级
- **世界观（세계관）**：背景、规则、氛围、约束
- **关系（관계）**：人物关系随时间的动态演化
- **场景（장면）**：分镜构成（컷구성）、叙述语调、情感标签
- **主题（테마）**：情感主题（정서테마）、作者意图

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
| `/oh-my-kimi:writer-memory query <question>` | 自然语言查询（支持韩语） |
| `/oh-my-kimi:writer-memory validate <character> <dialogue>` | 检查台词是否符合人物语调 |
| `/oh-my-kimi:writer-memory synopsis` | 生成情感导向的故事梗概 |
| `/oh-my-kimi:writer-memory export` | 把完整记忆导出为可读 markdown |
| `/oh-my-kimi:writer-memory backup` | 手动备份 |

## 记忆类型

### 캐릭터 메모리（Character Memory）

跟踪一致刻画所必需的单个人物属性：

| 字段 | 韩语 | 描述 |
|-------|--------|-------------|
| `arc` | 감정궤도 | 情感旅程（例如 "체념 -> 욕망자각 -> 선택"） |
| `attitude` | 태도 | 当前对生活 / 他人的态度 |
| `tone` | 대사톤 | 台词风格（例如 "담백"、"직설적"、"회피적"） |
| `speechLevel` | 말투 레벨 | 正式度：반말、존댓말、해체、혼합 |
| `keywords` | 핵심 단어 | 人物常用的特征词 / 短语 |
| `taboo` | 금기어 | 人物绝不说的词 / 短语 |
| `emotional_baseline` | 감정 기준선 | 默认情绪基线 |
| `triggers` | 트리거 | 引发情绪反应的触发点 |

**示例：**
```
/writer-memory char add 새랑
/writer-memory char update 새랑 arc "체념 -> 욕망자각 -> 선택"
/writer-memory char update 새랑 tone "담백, 현재충실, 감정억제"
/writer-memory char update 새랑 speechLevel "해체"
/writer-memory char update 새랑 keywords "그냥, 뭐, 괜찮아"
/writer-memory char update 새랑 taboo "사랑해, 보고싶어"
```

### 세계관 메모리（World Memory）

确立你故事所在的宇宙：

| 字段 | 韩语 | 描述 |
|-------|--------|-------------|
| `setting` | 배경 | 时间、地点、社会语境 |
| `rules` | 규칙 | 世界如何运作（魔法体系、社会规范） |
| `atmosphere` | 분위기 | 整体情绪与基调 |
| `constraints` | 제약 | 这个世界里**不**可能发生的事 |
| `history` | 역사 | 相关背景故事 |

### 관계 메모리（Relationship Memory）

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
```
/writer-memory rel add 새랑 해랑 romantic
/writer-memory rel update 새랑 해랑 "첫 키스 - 새랑 회피"
/writer-memory rel update 새랑 해랑 "해랑 고백 거절당함"
/writer-memory rel update 새랑 해랑 "새랑 먼저 손 잡음"
```

### 장면 메모리（Scene Memory）

跟踪每个场景及其情感结构：

| 字段 | 韩语 | 描述 |
|-------|--------|-------------|
| `title` | 제목 | 场景标识 |
| `characters` | 등장인물 | 谁出场 |
| `location` | 장소 | 发生地点 |
| `cuts` | 컷 구성 | 逐镜拆解 |
| `narration_tone` | 내레이션 톤 | 叙述者的语调风格 |
| `emotional_tag` | 감정 태그 | 主要情感（例如 "설렘+불안"） |
| `purpose` | 목적 | 该场景为何存在于故事中 |
| `before_after` | 전후 변화 | 人物在此场景前后发生了什么变化 |

### 테마 메모리（Theme Memory）

捕捉贯穿故事的深层意义：

| 字段 | 韩语 | 描述 |
|-------|--------|-------------|
| `name` | 이름 | 主题标识 |
| `expression` | 표현 방식 | 主题如何呈现 |
| `scenes` | 관련 장면 | 承载该主题的场景 |
| `character_links` | 캐릭터 연결 | 哪些人物承担这个主题 |
| `author_intent` | 작가 의도 | 你想让读者感受到什么 |

## 故事梗概生成（시놉시스）

`/synopsis` 命令用 5 个核心要素生成情感导向的摘要：

### 5 个核心要素（시놉시스 5요소）

1. **주인공 태도 요약**（主人公态度概述）
   - 主人公如何面对生活 / 爱 / 冲突
   - 核心情感立场
   - 示例："새랑은 상실을 예방하기 위해 먼저 포기하는 사람"

2. **관계 핵심 구도**（核心关系结构）
   - 推动故事的中心动态
   - 权力失衡与张力
   - 示例："사랑받는 자와 사랑하는 자의 불균형"

3. **정서적 테마**（情感主题）
   - 故事唤起的感受
   - 不是情节，而是情感真相
   - 示例："손에 쥔 행복을 믿지 못하는 불안"

4. **장르 vs 실제감정 대비**（类型期待 vs 真实情感对比）
   - 表层类型预期 vs 实际情感内容
   - 示例："로맨스지만 본질은 자기수용 서사"

5. **엔딩 정서 잔상**（结尾情感余韵）
   - 故事结束后留下的感觉
   - 示例："씁쓸한 안도, 불완전한 해피엔딩의 여운"

## 人物校验（캐릭터 검증）

`/validate` 命令检查台词是否符合人物既定的声音。

### 检查项

| 检查项 | 描述 |
|-------|-------------|
| **Speech Level** | 敬语 / 半语等级是否匹配？（반말 / 존댓말 / 해체） |
| **Tone Match** | 情感基调是否合适？ |
| **Keyword Usage** | 是否用了人物特征词？ |
| **Taboo Violation** | 是否用了禁忌词？ |
| **Emotional Range** | 是否在人物情绪基线之内？ |
| **Context Fit** | 是否适合当下关系与场景？ |

### 校验结果

- **PASS**：台词与人物一致
- **WARN**：有轻微不一致，可能是有意为之
- **FAIL**：与既定声音明显偏离

**示例：**
```
/writer-memory validate 새랑 "사랑해, 해랑아. 너무 보고싶었어."
```
输出：
```
[FAIL] 새랑 validation failed:
- TABOO: "사랑해" - character avoids direct declarations
- TABOO: "보고싶었어" - character suppresses longing expressions
- TONE: Too emotionally direct for 새랑's 담백 style

Suggested alternatives:
- "...왔네." (minimal acknowledgment)
- "늦었다." (deflection to external fact)
- "밥 먹었어?" (care expressed through practical concern)
```

## 上下文查询（맥락 질의）

针对记忆的自然语言查询，完全支持韩语。

### 示例查询

```
/writer-memory query "새랑은 이 상황에서 뭐라고 할까?"
/writer-memory query "규리의 현재 감정 상태는?"
/writer-memory query "해랑과 새랑의 관계는 어디까지 왔나?"
/writer-memory query "이 장면의 정서적 분위기는?"
/writer-memory query "새랑이 먼저 연락하는 게 맞아?"
/writer-memory query "해랑이 화났을 때 말투는?"
```

系统会从所有相关记忆类型中综合给出答案。

## 行为

1. **Init 时**：创建 `.writer-memory/memory.json`，含项目元数据与空集合
2. **自动备份**：修改前先备份到 `.writer-memory/backups/`
3. **韩语优先**：情感词汇贯穿使用韩语术语
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
```
Agent(subagent_type="oh-my-kimi:architect",
     model="opus",
     prompt="Analyze 새랑's arc across all scenes...")
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

```
# 初始化项目
/writer-memory init 봄의 끝자락

# 添加人物
/writer-memory char add 새랑
/writer-memory char update 새랑 arc "체념 -> 욕망자각 -> 선택"
/writer-memory char update 새랑 tone "담백, 현재충실"
/writer-memory char update 새랑 speechLevel "해체"

/writer-memory char add 해랑
/writer-memory char update 해랑 arc "확신 -> 동요 -> 기다림"
/writer-memory char update 해랑 tone "직진, 솔직"
/writer-memory char update 해랑 speechLevel "반말"

# 建立关系
/writer-memory rel add 새랑 해랑 romantic
/writer-memory rel update 새랑 해랑 "첫 만남 - 해랑 일방적 호감"
/writer-memory rel update 새랑 해랑 "새랑 거절"
/writer-memory rel update 새랑 해랑 "재회 - 새랑 내적 동요"

# 设定世界
/writer-memory world set setting "서울, 현대, 20대 후반 직장인"
/writer-memory world set atmosphere "도시의 건조함 속 미묘한 온기"

# 添加主题
/writer-memory theme add "포기하지 않는 사랑"
/writer-memory theme add "자기 보호의 벽"

# 添加场景
/writer-memory scene add "옥상 재회"

# 写作时查询
/writer-memory query "새랑은 이별 장면에서 어떤 톤으로 말할까?"

# 校验台词
/writer-memory validate 새랑 "해랑아, 그만하자."

# 生成梗概
/writer-memory synopsis

# 导出参考
/writer-memory export
```

### 快速查看人物

```
/writer-memory char 새랑
```

输出：
```
## 새랑

**Arc (감정궤도):** 체념 -> 욕망자각 -> 선택
**Attitude (태도):** 방어적, 현실주의
**Tone (대사톤):** 담백, 현재충실
**Speech Level (말투):** 해체
**Keywords (핵심어):** 그냥, 뭐, 괜찮아
**Taboo (금기어):** 사랑해, 보고싶어

**Relationships:**
- 해랑: romantic (intimacy: 6/10, status: healing)

**Scenes Appeared:** 옥상 재회, 카페 대화, 마지막 선택
```

## 存储 Schema

```json
{
  "version": "1.0",
  "project": {
    "name": "봄의 끝자락",
    "genre": "로맨스",
    "created": "2024-01-15T09:00:00Z",
    "lastModified": "2024-01-20T14:30:00Z"
  },
  "characters": {
    "새랑": {
      "arc": "체념 -> 욕망자각 -> 선택",
      "attitude": "방어적, 현실주의",
      "tone": "담백, 현재충실",
      "speechLevel": "해체",
      "keywords": ["그냥", "뭐", "괜찮아"],
      "taboo": ["사랑해", "보고싶어"],
      "emotional_baseline": "평온한 무관심",
      "triggers": ["과거 언급", "미래 약속"]
    }
  },
  "world": {
    "setting": "서울, 현대, 20대 후반 직장인",
    "rules": [],
    "atmosphere": "도시의 건조함 속 미묘한 온기",
    "constraints": [],
    "history": ""
  },
  "relationships": [
    {
      "id": "rel_001",
      "from": "새랑",
      "to": "해랑",
      "type": "romantic",
      "dynamic": "해랑 주도 → 균형",
      "speechLevel": "반말",
      "evolution": [
        { "timestamp": "...", "change": "첫 만남 - 해랑 일방적 호감", "catalyst": "우연한 만남" },
        { "timestamp": "...", "change": "새랑 거절", "catalyst": "과거 트라우마" },
        { "timestamp": "...", "change": "재회 - 새랑 내적 동요", "catalyst": "옥상에서 재회" }
      ],
      "notes": "새랑의 불신 vs 해랑의 기다림",
      "created": "..."
    }
  ],
  "scenes": [
    {
      "id": "scene-001",
      "title": "옥상 재회",
      "characters": ["새랑", "해랑"],
      "location": "회사 옥상",
      "cuts": ["해랑 먼저 발견", "새랑 굳은 표정", "침묵", "해랑 먼저 말 걸기"],
      "narration_tone": "건조체",
      "emotional_tag": "긴장+그리움",
      "purpose": "재회의 어색함과 남은 감정 암시",
      "before_after": "새랑: 무관심 -> 동요"
    }
  ],
  "themes": [
    {
      "name": "포기하지 않는 사랑",
      "expression": "해랑의 일관된 태도",
      "scenes": ["옥상 재회", "마지막 고백"],
      "character_links": ["해랑"],
      "author_intent": "집착이 아닌 믿음의 사랑"
    }
  ],
  "synopsis": {
    "protagonist_attitude": "새랑은 상실을 예방하기 위해 먼저 포기하는 사람",
    "relationship_structure": "기다리는 자와 도망치는 자의 줄다리기",
    "emotional_theme": "사랑받을 자격에 대한 의심",
    "genre_contrast": "로맨스지만 본질은 자기수용 서사",
    "ending_aftertaste": "불완전하지만 따뜻한 선택의 여운"
  }
}
```

## 文件结构

```
.writer-memory/
├── memory.json          # 主记忆文件
├── backups/             # 改动前的自动备份
│   ├── memory-2024-01-15-090000.json
│   └── memory-2024-01-20-143000.json
└── exports/             # markdown 导出
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
- 跑 `/writer-memory status` 诊断

**校验太严格？**
- 检查 taboo 列表是否有误录
- 考虑人物是否在成长（弧线推进）
- 戏剧时刻里有意打破模式是合理的

**query 找不到上下文？**
- 确保相关数据已在记忆里
- 试更具体的查询
- 检查人物名是否完全一致
