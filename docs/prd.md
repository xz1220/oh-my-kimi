# oh-my-kimi PRD

## 我们要做什么

**Kimi CLI 的精选 skill / hook / MCP 包**。一条 curl 安装，让 Kimi CLI 用户立刻拥有 oh-my-claudecode（OMC）风格的体验：精选 agent team、经典生命周期 hook、常用 MCP 一键 add、推荐配置开箱即用。

不是新 CLI，不是 fork，**完全寄生在 Kimi CLI 既有的扩展面上**。代码量预期在数百行配置 + 一组 SKILL.md 文档，不在数万行 agent runtime。

## 为什么是「精选包」而不是 fork

[Moonshot kimi-cli](https://github.com/MoonshotAI/kimi-cli) 的扩展面调研结论（详见 `docs/research/kimi-cli-extension-surface.md`，TBD 补）：

| 扩展点 | Kimi CLI 状态 | 备注 |
|---|---|---|
| Skill（`SKILL.md`） | 完整支持 | 跨品牌读 `~/.kimi/` / `~/.claude/` / `~/.codex/` 等多个目录 |
| Hook（13 个生命周期事件） | 完整支持 | 事件名几乎和 Claude Code 一字不改 |
| MCP（HTTP / stdio / OAuth） | 完整支持 | `mcpServers` 配置 schema 和 Claude Code 一样 |
| Subagent（YAML，含 `extend`/`tools`/`subagents`） | 完整支持 | |
| AGENTS.md（项目级上下文） | 完整支持 | 类似 Claude Code 的 CLAUDE.md |
| Plugin（git/zip URL 安装） | 支持，**但无 marketplace** | 没有官方 registry，需自己分发 |
| 自定义 slash | ⚠️ 只能借 Skill 暴露为 `/skill:<name>` | OMC 风格的 `/review` 在 Kimi 上是 `/skill:review` |
| 多 backend（OpenAI 兼容） | 完整支持 | 可挂任意 endpoint |

**6/8 完整支持**，且和 Claude Code 设计同构度极高 —— 这是 oh-my-kimi 能存在的前提。

## 给谁用（ICP）

- **目标用户**：Kimi CLI / Kimi Code 用户（GitHub 上 8.5k star、1k fork 的盘子），尤其是从 Claude Code / Codex 迁移过来、习惯了 OMC 那一套精选体验的人
- **次级用户**：Claude Code 用户（因为 skill 包跨 host 生效，他们装一份等于同时配两个 CLI）
- **不在目标**：纯 IDE 用户（Cursor / Windsurf）—— 那些是另一个生态，不在本项目范围

## 核心价值（用户装上之后爽在哪）

1. **5 分钟拥有 OMC 同款体验**：一条 curl 装好 skill + hook + MCP + subagent 模板
2. **中文优先**：所有 skill 描述、prompt 注入、文档都中文写就（差异化竞争的关键 —— OMC / OMX 都是英文为主）
3. **跨 host 红利**：同一份 skill 包同时给 Kimi CLI 和 Claude Code 用，不用维护两份
4. **国内场景集成**：默认带飞书 / 钉钉 / 微信 MCP server 推荐（v1+），切中国内开发者实际工作流
5. **可拆可选**：包是 modular 的，用户可以只装 skills 不装 hooks，或者反过来

## v0 范围

目标：1-2 周做完，能给 10 个 Kimi CLI 用户装上跑。

### 仓库结构

```
oh-my-kimi/
├── README.md
├── LICENSE                # Apache-2.0（对齐 Kimi CLI 上游）
├── install.sh             # 一键安装脚本
├── uninstall.sh           # 一键卸载（重要：必须可逆）
├── skills/                # SKILL.md 集合
│   ├── code-review/
│   ├── security-review/
│   ├── tdd-driver/
│   ├── debug-helper/
│   └── ...（5-10 个起步）
├── agents/                # YAML subagent 模板
│   ├── reviewer.yaml
│   └── planner.yaml
├── hooks/                 # TOML hook 片段（用户 cat >> config.toml）
│   ├── auto-format.toml
│   ├── protect-env.toml
│   └── notify-on-stop.toml
├── mcp/                   # 推荐 MCP server 一键 add 脚本
│   ├── add-context7.sh
│   ├── add-chrome-devtools.sh
│   └── add-recommended-all.sh
├── docs/
│   ├── prd.md
│   ├── install.md
│   ├── skills.md          # 每个 skill 的中文说明
│   └── research/
│       └── kimi-cli-extension-surface.md  # 调研结论存档
└── examples/              # 几个实际使用场景的演示 transcript
```

### 安装方式（v0）

```bash
curl -fsSL https://raw.githubusercontent.com/xz1220/oh-my-kimi/main/install.sh | bash
```

实际动作：clone 仓库到 `~/.oh-my-kimi/`，把 `skills/` symlink 到 `~/.kimi/skills/`，把 `agents/` symlink 到 `~/.kimi/agents/`（如约定路径），把 hooks/mcp 内容 append / merge 到 `~/.kimi/config.toml` 和 `~/.kimi/mcp.json`（**append 前自动备份**）。

### v0 不做

- Plugin 形态（没有 marketplace 加持，分发收益不划算）
- Web UI / HUD（OMC 有 HUD，v0 不抄）
- 自定义 slash 命令（Kimi CLI 没这个扩展点，绕开）
- Cursor / Windsurf 适配
- 多语言文档（v0 只中文 + 英文 README 顶部一段）

## v1+ 演进

v0 验证有人用之后：

- **MiniMax Mini-Agent / GLM-CLI 适配**：如果它们的扩展面够，把 skill 包也接过去 → 项目自然演化为 `oh-my-cn-coders`（多 host）
- **自建 git-based registry**：在 Moonshot 出 marketplace 之前，自己搭一个 git 索引仓库充当社区 registry，让用户能搜 / 评分 / 装第三方 skill 包
- **打通飞书 / 钉钉 / 企业微信 MCP**：让 Kimi CLI 能直接和国内办公系统联动
- **HUD / 状态栏**：抄 OMX 的 HUD 思路（v0 跳过，验证完核心价值再补）

## 待定决策

### 定位层（**先聊清这一层**）

- [ ] **「跨 host」要不要作为头版卖点**？
  - 选 A：头版打「Kimi CLI 同款 OMC」→ 受众聚焦 Kimi 用户
  - 选 B：头版打「同一份 skill 包给 Kimi + Claude Code 用」→ 受众更大但稀释 Kimi 标签
  - 选 C：项目名保留 `oh-my-kimi`，文档里突出跨 host 红利（推荐）
- [ ] **要不要给 GLM Coding Plan / DeepSeek 用户做兼容**？
  - 智谱用户主流玩法是「GLM 模型 + Claude Code 壳」—— 他们其实就是 Claude Code 用户，skill 包对他们天然生效。这是不是该作为额外受众显式拉进来？
- [ ] **是否要包装一层「auto-install presets」**：`profile-web-dev` / `profile-backend` / `profile-data` 三种预设，按用户身份一键装不同 skill 子集

### 工程层

- [ ] **install 脚本要不要走包管理器**（pipx / npx / brew tap）？v0 用 curl + bash 最简单，但管理升级麻烦
- [ ] **skill 内容从哪来**：从头写 / 抄 OMC（注意 license）/ 抄 Anthropic agent-skills / 三者混合
- [ ] **如何处理与上游 Kimi CLI 升级的兼容性**：hook 事件名 / config schema 一旦改了怎么追？需要 CI 锁版本测试？
- [ ] **AGENTS.md 是否要默认注入一份 oh-my-kimi 的元信息**，让 Kimi 知道这些 skill 存在？

### 品牌层

- [ ] 中文项目名 / slogan
- [ ] 是否注册一个简短的安装域名（`get.ohmykimi.dev` 之类）
- [ ] Logo（v0 不重要，先文字）

## 死亡风险（必须严肃对待）

1. **Moonshot 自己出官方精选包 / marketplace** → oh-my-kimi 被官方碾压
   - 应对：保持中文 + 国内场景的差异化，让官方版本和社区版本互补而非竞争
2. **Kimi CLI 用户基数太小** → 装的人太少，没有反馈飞轮
   - 应对：v0 就显式打「Kimi + Claude Code 双 host」，把 Claude Code 庞大的用户群也拉进来
3. **「直接用 Claude Code + Kimi 后端」绕过本项目** → Kimi 已支持 Claude API 兼容，用户为什么不直接 Claude Code 接 Kimi 模型？
   - 应对：本项目的价值不在「让你用 Kimi」，在「让你用 Kimi CLI（host）」 —— Kimi CLI 自己也是有价值的 host（中文体验更佳、本土能力集成更顺）。**这一点要在 README 头版讲清，否则项目立项逻辑站不住**
4. **skill / hook 跟随上游 break** → 每次 Kimi CLI 升级都可能改 schema，维护成本高
   - 应对：CI 锁 Kimi CLI 版本做集成测试；明确支持的 Kimi CLI 版本范围

**第 3 项是最严肃的风险**，立项前需要给出明确回答。

## MVP 路线（3-4 周拿到第一手数据）

| Week | 范围 | 验证什么 |
|---|---|---|
| **Week 1** | 仓库骨架 + install.sh + 3 个核心 skill（review / debug / tdd）+ 2 个 hook + 3 个 MCP 推荐 | 能跑通完整安装 → 使用 → 卸载闭环 |
| **Week 2** | 补到 10 个 skill；写 docs/install.md 和 docs/skills.md；examples 写 2-3 个真实使用 transcript | 文档质量过关，新用户 5 分钟内能用起来 |
| **Week 3** | 邀请 5-10 个 Kimi CLI / Claude Code 重度用户试装，每天观察反馈 | 装上之后有人**主动用第二次**吗？有人愿意提 PR 加 skill 吗？ |
| **Week 4** | 写一篇中文技术博客 +（可选）即刻 / Twitter 推文，看自然扩散 | star 增速 / 装机量 / Issue 量 |

**Week 4 末复盘决策**：
- 有人主动提 PR 加 skill / 装机数 > 50 → 进 v1（多 host 扩张 + registry）
- 反响平淡 / 没人提 PR → 检查死亡风险 #3 是否成立，决定调整定位还是 archive

## 关联

- 上游 CLI：[`MoonshotAI/kimi-cli`](https://github.com/MoonshotAI/kimi-cli)（Apache-2.0）
- 灵感对照：
  - [`Yeachan-Heo/oh-my-claudecode`](https://github.com/Yeachan-Heo/oh-my-claudecode) —— Claude Code 多 agent 编排插件（19 agent + 36 skill）
  - [`Yeachan-Heo/oh-my-codex`](https://github.com/Yeachan-Heo/oh-my-codex) —— OpenAI Codex CLI 版本
  - [`opensoft/oh-my-opencode`](https://github.com/opensoft/oh-my-opencode) —— OpenCode 版本
- 邻近 idea：[`prospector`](../../prospector)（云端 skill 发现 / 加载 —— oh-my-kimi 是 skill 包，prospector 是 skill 分发，未来可能交汇）
