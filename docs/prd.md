# oh-my-kimi PRD

> **版本说明**：本 PRD v2（2026-05-11 重写）。v1 把项目框成「Kimi CLI 的精选 skill 包」，调研后发现该框定是误读 —— 见下文「立项依据」。

## 我们要做什么

**把 Yeachan-Heo 的 `oh-my-*` 谱系 port 到 Moonshot Kimi CLI**。复刻 `oh-my-claudecode` (OMC) / `oh-my-codex` (OMX) 的角色 catalog、skill catalog、工作流（`$deep-interview → $ralplan → $ralph → $team`）到 Kimi CLI 这个 host。

**核心动作不是「设计」，是「down-port」**：上游已经把 host-无关的角色 / skill / 工作流 spec 抽象出来了，我们的工程价值落在「Kimi CLI 这个 host 的适配层」。

## 立项依据（调研结论）

### 发现一：OMC 与 OMX 不是不同哲学，是同一 spec 在不同 host 上的 down-port

调研（2026-05-11，见 `docs/research/omc-omx-divergence.md`）发现：

- OMC 有 19 个 agent，OMX 有 33 个专家 prompt + `$team` 并行；**两者共享角色谱系**（executor / critic / architect / orchestrator / debugger 等）
- OMX README 自己写明 "Inspired by oh-my-opencode" —— 整个谱系起源于另一个韩国开发者 code-yeongyu 的 opencode 项目，作者本身就是在做横向移植
- 时间线：opencode-lite (2026-01-06) → OMC (2026-01-09) → OMX (2026-02-02) → oh-my-gemini (2026-03-05)；**24 天迭代一个 host，明显是工程化 port**
- 表面差异（OMC 用 Task tool subagent vs OMX 用 tmux 多窗）**根源是 host 能力差**：Claude Code 有 `Task(subagent_type=...)` in-process delegation 原语，Codex CLI 没有 `SubagentStop` hook（OMX 官方 doc 标注 `not-supported-yet`），只能拉 tmux 多进程

### 发现二：Kimi CLI 处于「Claude Code 那一极」，可走 OMC 路线

调研（2026-05-11，见 `docs/research/kimi-cli-extension-surface.md`）：

| 关键原语 | Claude Code | Codex CLI | **Kimi CLI** |
|---|---|---|---|
| In-process subagent | ✅ Task tool | ❌ | ✅ YAML subagent + `extend`/`tools` |
| `SubagentStop` hook | ✅ | ❌ | ✅ 13 个 hook 事件含 SubagentStart/Stop |
| Skill 注册位 | `~/.claude/skills/` | 弱 | ✅ `SKILL.md` + 跨品牌读 `~/.claude/skills/` |
| MCP | ✅ | ✅ | ✅ schema 与 Claude 一致 |
| 多 backend | OAuth + API | OpenAI | ✅ 任意 OpenAI 兼容 |

**结论**：Kimi CLI 是 OMC 路线（in-loop delegation）的目标 host，不必走 OMX 的 tmux 兜底。这让 oh-my-kimi 的工程难度比 OMX 还低。

### 发现三：跨 host 红利

Kimi CLI 原生读 `~/.claude/skills/`。同一份 skill 包对 Kimi CLI 和 Claude Code **双 host 生效**，无需维护两份。

## 项目定位

**oh-my-kimi = `oh-my-*` 谱系在国产 host 的第一环**。

- 不是「Kimi 版 OMC」（暗示是抄袭/低配版）
- 不是从零设计的新框架（不存在那么多原创空间）
- 是把已被 3 个 host（opencode / claude / codex）验证过的范式，**接到 Moonshot 这个国产 host 上**

## 给谁用（ICP）

- **首要**：Kimi CLI / Kimi Code 用户（GitHub 8.5k star / 1k fork 盘子），尤其是从 Claude Code / Codex 迁移过来、习惯了 OMC 那套精选体验的人
- **次级（跨 host 红利）**：Claude Code 用户，因 skill 包跨 host 生效，他们装一份等于配两个 CLI
- **第三级（潜在）**：GLM Coding Plan 用户（实际用 Claude Code + GLM 后端，对他们 oh-my-kimi 等价于 Claude Code 的精选包）

## 核心价值

1. **Kimi CLI 用户终于有 OMC 同款体验**：5 分钟一条 curl 装好
2. **中文优先**：所有角色描述 / prompt 注入 / skill 文档全中文（OMC/OMX 都是英文，这是差异化关键）
3. **跨 host 红利**：同一份 skill 包同时给 Kimi CLI 和 Claude Code 用
4. **国内场景预集成**：默认带飞书 / 钉钉 / 企业微信 MCP server 推荐（v1+）
5. **可拆可选**：模块化，用户可以只装 agents 不装 hooks，反之亦然

## v0 范围

目标：**2 周做完**，能给 10 个 Kimi CLI 用户装上跑（比 v1 PRD 的 3-4 周大幅缩减 —— 因为不重写 spec）。

### 工程拆分

| 层 | 来源 | 改动量 |
|---|---|---|
| **角色 catalog**（agents/） | fork 自 OMC + 翻译为中文 | 小：MIT license，结构镜像，主要是 prompt 翻译 + 适配 Kimi 模型路由（K2 vs sonnet/opus） |
| **Skill catalog**（skills/） | fork 自 OMC + 翻译 | 小：SKILL.md 格式 Kimi 原生支持 |
| **工作流命令**（$deep-interview / $ralplan / $ralph / $team） | 复刻命名 + 改 Kimi slash 适配 | 中：Kimi 没有 `.claude/commands/*.md` 等价物，要借 Skill 暴露为 `/skill:<name>` |
| **Hook 配置**（hooks.toml） | 抄 OMC 思路 + 改 Kimi 事件名 | 小：13 个事件大体对齐，几处细微差异需要 wrap |
| **MCP 推荐合集** | 通用 + Kimi 友好的 | 小：mcp.json schema 完全一致 |
| **install / uninstall 脚本** | 原创 | 中：处理 symlink、备份、跨平台 |

### 仓库结构

```
oh-my-kimi/
├── README.md
├── LICENSE                        # Apache-2.0（对齐 Kimi CLI 上游）
├── NOTICE                         # 注明 attribution to OMC (MIT)
├── install.sh / uninstall.sh
├── agents/                        # YAML subagent（fork 自 OMC）
│   ├── executor.yaml
│   ├── critic.yaml
│   ├── architect.yaml
│   ├── planner.yaml
│   └── ...
├── skills/                        # SKILL.md（fork 自 OMC）
│   ├── deep-interview/            # → /skill:deep-interview
│   ├── ralplan/                   # → /skill:ralplan
│   ├── ralph/
│   ├── code-review/
│   ├── security-review/
│   ├── tdd-driver/
│   ├── debug-helper/
│   └── ...
├── hooks/
│   ├── auto-format.toml
│   ├── protect-env.toml
│   ├── session-notify.toml
│   └── README.md                  # 怎么 cat >> ~/.kimi/config.toml
├── mcp/
│   ├── add-context7.sh
│   ├── add-chrome-devtools.sh
│   └── add-recommended-all.sh
├── docs/
│   ├── prd.md
│   ├── install.md
│   ├── skills.md                  # 每个 skill 的中文说明
│   ├── attribution.md             # 详细列出从 OMC fork 了哪些
│   └── research/
│       ├── omc-omx-divergence.md            # OMC vs OMX 调研存档
│       └── kimi-cli-extension-surface.md    # Kimi CLI 扩展面调研存档
└── examples/                      # 真实使用 transcript 截图
```

### 安装方式

```bash
curl -fsSL https://raw.githubusercontent.com/xz1220/oh-my-kimi/main/install.sh | bash
```

动作：clone 到 `~/.oh-my-kimi/`，symlink `agents/` `skills/` 到 `~/.kimi/`，append `hooks/*.toml` 到 `~/.kimi/config.toml`（**先备份**），跑 MCP add 脚本。

### v0 不做

- HUD / 状态面板（OMX 有，v0 跳过；tmux 集成成本高且 Kimi CLI 用户未必都装 tmux）
- 自建 git-based registry / plugin marketplace
- Web UI
- 多语言文档（v0 中文为主，英文 README 顶部一段）
- Cursor / Windsurf 适配

## v1+ 演进

- **HUD 状态面板**：抄 OMX 的 `omx hud --watch` 思路，给 Kimi CLI 配 tmux HUD
- **多国产 host 适配**：MiniMax Mini-Agent / GLM-CLI 的扩展面如够，把 skill catalog 接过去 → 演化为 `oh-my-cn-coders`（覆盖国产谱系）
- **贡献回上游**：和 Yeachan-Heo 沟通，看 oh-my-kimi 能不能并入 oh-my-* 官方谱系（变成 `xz1220/oh-my-kimi`），或保持独立维护建立协作关系
- **国内 MCP 集成**：飞书 / 钉钉 / 企业微信 / 阿里云 / 腾讯云 MCP server 默认推荐

## 待定决策（优先级排序）

### P0：定位 / 策略层（**动代码前必须想清**）

- [ ] **与上游 Yeachan-Heo 的关系**：四选一
  - A. 完全独立维护（xz1220/oh-my-kimi）
  - B. 给 Yeachan-Heo 发 issue / PR 提议把 oh-my-kimi 并入官方谱系
  - C. 先独立做出 v0，验证有人用之后再去找上游谈合并
  - D. 直接以 fork 形式开（`xz1220/oh-my-kimi` fork from `Yeachan-Heo/oh-my-claudecode`）
- [ ] **死亡风险 #3 怎么回答**：「用户为什么不直接 Claude Code + Kimi 后端，绕过 oh-my-kimi」—— Kimi 已支持 Claude API 兼容。**这个问题决定项目立项逻辑站不站得住**
- [ ] **中文化深度**：只翻 prompt / 翻 prompt + skill 描述 / 翻全部含 README / 给每个角色起中文名（"executor" → "执行者"还是保留英文）

### P1：工程层

- [ ] **fork 还是抄**：MIT 允许直接 fork，但 oh-my-kimi 仓库本身要不要 fork from OMC？fork 的好处是历史可见 + 自动 attribution，坏处是 GitHub 标签会显示 forked，发现度低；抄 + NOTICE 文件的方式更干净但 attribution 责任更重
- [ ] **角色路由**：OMC 把 haiku/sonnet/opus 三 tier 分给不同 agent，Kimi 只有 K2 一个主力模型（虽然有 K2-turbo / K2.5 / K2.6 等变体）。怎么映射？需不需要做 model alias 配置层？
- [ ] **跨 host 测试矩阵**：Kimi CLI + Claude Code 双 host 都要测，CI 怎么搭？
- [ ] **Kimi CLI 版本兼容**：锁哪个版本？升级 break 怎么办？

### P2：品牌 / 推广

- [ ] 中文项目名（"oh-my-kimi" 还是「我的 Kimi」之类）
- [ ] 安装域名（`get.ohmykimi.dev` ？）
- [ ] Logo

## 死亡风险

按严重度排序：

### #1：「Claude Code + Kimi 后端」绕过本项目

Kimi 已支持 Claude API 兼容，用户为什么不直接用 Claude Code + Kimi 模型？

**应对**：本项目价值不在「让你用 Kimi 模型」，在「让你用 Kimi CLI 这个 host」—— Kimi CLI 自身的中文体验、国内网络可达性、本土 MCP 集成是 Claude Code + Kimi 后端不可替代的。**但这个论证需要在 README 头版明说，否则项目逻辑站不住**。

⚠️ 这是 P0 决策中最严肃的一个。

### #2：Yeachan-Heo 自己出 oh-my-kimi

作者已 24 天 port 一个 host 的节奏，理论上随时可能补上 Kimi（Kimi CLI 在 GitHub 有 8.5k star，是值得 port 的 host）。

**应对**：
- 速度：抢在他之前把社区做起来
- 关系：主动联系，看能不能直接进官方谱系（待定决策 P0 #1）
- 差异化：中文 + 国内场景，这是首尔开发者短期内不会做的方向

### #3：Moonshot 出官方精选包

可能性：低（Moonshot 没释放过这方向信号，且公司层做 marketplace 优先级不会高）。

**应对**：保持中文 + 国内场景差异化，与官方互补。

### #4：上游 break

OMC / Kimi CLI 升级都可能 break。

**应对**：CI 锁版本测试；明确支持的 OMC commit / Kimi CLI 版本范围。

## MVP 路线（2-3 周）

| Week | 范围 | 验证什么 |
|---|---|---|
| **Week 1** | fork OMC 角色 catalog 到 agents/；翻译 5 个核心角色（executor / critic / architect / planner / orchestrator）；写 install.sh 跑通 1 个 skill | 工程闭环：fork → 翻译 → 安装 → Kimi CLI 能调起 |
| **Week 2** | 全量翻译角色 + skill；补 hook 配置 + MCP 推荐；写 docs/install.md 和 docs/skills.md | 文档质量过关，新用户 5 分钟内能用起来 |
| **Week 3** | 邀请 5-10 个 Kimi CLI / Claude Code 重度用户试装；写中文技术博客 + 即刻 / Twitter 推文 | 装机量 / star / 主动 PR |

**Week 3 末复盘**：
- 装机 > 50 / 有人提 PR → 进 v1（HUD + 多 host + 联系 Yeachan-Heo）
- 反响平淡 → 检查死亡风险 #1 是否成立，决定调整定位或 archive

## 关联

- 上游 host：[`MoonshotAI/kimi-cli`](https://github.com/MoonshotAI/kimi-cli)（Apache-2.0）
- 上游 spec 来源：
  - [`Yeachan-Heo/oh-my-claudecode`](https://github.com/Yeachan-Heo/oh-my-claudecode)（MIT，**主要 fork 来源**）
  - [`Yeachan-Heo/oh-my-codex`](https://github.com/Yeachan-Heo/oh-my-codex)（license 待核实）
  - [`code-yeongyu/oh-my-openagent`](https://github.com/code-yeongyu/oh-my-openagent)（谱系真正起源）
- 邻近 idea：`prospector`（云端 skill 分发；与本项目互补：oh-my-kimi 是「精选包」，prospector 是「发现 + 加载机制」）
