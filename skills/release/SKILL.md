---
name: release
description: 通用发布助手 —— 分析仓库的发布规则，缓存到 .omk/RELEASE_RULE.md，然后引导你完成发布
level: 3
---

# Release Skill

一个轻量、感知仓库的发布助手。首次运行时会检视项目与 CI 推导出发布规则，存到 `.omk/RELEASE_RULE.md` 以备后用，然后按这些规则带你完成一次发布。

## 用法

```
/oh-my-kimi:release [version]
```

- `version` 可选。省略时由 skill 询问。接受 `patch`、`minor`、`major`，或显式 semver，如 `2.4.0`。
- 加 `--refresh` 即便缓存规则文件存在也强制重新分析仓库。

## 执行流程

### 第 0 步 —— 加载或构建发布规则

检查 `.omk/RELEASE_RULE.md` 是否存在。

**如果不存在（或传了 `--refresh`）：** 跑下面的完整仓库分析并写入文件。

**如果存在：** 读取文件。然后做一次快速 delta 检查 —— 扫描 `.github/workflows/`（或等价的 CI 目录：`.circleci/`、`.travis.yml`、`Jenkinsfile`、`bitbucket-pipelines.yml`、`gitlab-ci.yml`），看是否有比规则文件里 `last-analyzed` 时间戳更新的修改。如果相关 workflow 文件变了，对相应章节重跑分析并更新文件。报告变更内容。

---

### 第 1 步 —— 仓库分析（首次或 --refresh）

检视仓库并回答下列问题。把答案写入 `.omk/RELEASE_RULE.md`。

#### 1a. 版本来源

- 找出所有匹配 `package.json` / `pyproject.toml` / `Cargo.toml` / `build.gradle` / `VERSION` 文件等里当前版本字符串的文件。
- 列出每个文件以及用于定位版本的字段或正则模式。
- 检测是否存在发布自动化脚本（例如 `scripts/release.*`、`Makefile release` 目标、`bump2version`、`release-it`、`semantic-release`、`changesets`、`goreleaser`）。

#### 1b. 仓库 / 分发

- npm（`package.json` 含 `publishConfig` 或 CI 里有 `npm publish`）、PyPI（`pyproject.toml` + `twine` / `flit`）、Cargo（`Cargo.toml`）、Docker（`Dockerfile` + push 步骤）、GitHub Packages、其他。
- 是否有 CI 步骤在 tag push 时自动发布？是哪个 workflow 文件与 job？

#### 1c. 发布触发

- 识别什么触发发布：tag push（`v*`）、手动 dispatch（`workflow_dispatch`）、合并到 main/master、release 分支合并、commit message 模式。

#### 1d. 测试门

- 识别测试命令以及它在 CI 里的运行位置。
- 发布前是否要求测试通过？记录任何绕过 flag。

#### 1e. 发布说明 / Changelog

- 是否存在 `CHANGELOG.md` 或 `CHANGELOG.rst`？
- 使用什么约定：Keep a Changelog、Conventional Commits、GitHub 自动生成、无？
- 是否有 release body 文件（如 `.github/release-body.md`）在 tag 前提交？

#### 1f. 首次用户检查

- `.github/workflows/`（或等价位置）里是否存在发布 workflow？若无，标出并提议脚手架。
- 是否有 `.gitignore` 条目阻止构建产物被提交？若无，标出。
- 是否在使用 git tag？跑 `git tag --list` 检查。若没有 tag，标出并解释最佳实践。

---

### 第 2 步 —— 写入 `.omk/RELEASE_RULE.md`

按此结构创建或覆盖文件：

```markdown
# Release Rules
<!-- last-analyzed: YYYY-MM-DDTHH:MM:SSZ -->

## 版本来源
<!-- 文件列表 + 模式 -->

## 发布触发
<!-- 触发发布的方式 -->

## 测试门禁
<!-- 命令 + CI job 名 -->

## 注册表 / 分发
<!-- npm、PyPI、Docker 等 + 负责发布的 CI job -->

## 发布说明策略
<!-- 约定 + 文件 -->

## CI 工作流文件
<!-- 相关 workflow 文件路径 -->

## 首次设置缺口
<!-- 分析中发现的缺失项，或 "none" -->
```

---

### 第 3 步 —— 确定版本

如果用户提供了 version 参数，用它。否则：

1. 展示当前版本（来自主版本文件）。
2. 展示 `patch`、`minor`、`major` 各自会产生什么版本。
3. 让用户选择。

校验选择的版本是合法的 semver 字符串。

---

### 第 4 步 —— 发布前清单

根据发布规则给出一份清单。至少包括：

- [ ] 本次发布所要包含的改动已经全部 commit 并 push
- [ ] CI 在目标分支上是绿的
- [ ] 测试本地通过（运行测试门命令）
- [ ] 版本号已 bump 到所有版本来源文件
- [ ] 发布说明 / changelog 准备好（见第 5 步）

让用户确认后再继续，或在用户说「go ahead」时逐条执行。

---

### 第 5 步 —— 发布说明指引

帮用户写出好的发布说明。沿用仓库使用的约定。在没有检测到约定时的默认指引：

**好的发布说明该满足：**
- 以**对用户的改变**开头，而不是内部实现细节。
- 按类型分组：`New Features`、`Bug Fixes`、`Breaking Changes`、`Deprecations`、`Internal / Chores`。
- 每条：一句话、链接到 PR 或 issue，外部贡献者署名致谢。
- **Breaking changes** 放最前面，必须附迁移路径。
- 用户看不到的改动（重构、CI 调整、纯测试改动）可省略，除非影响构建可复现性。

**示例条目格式：**
```
### Bug 修复
- Fix session drop on token expiry (#123) — @contributor
```

如果仓库使用 Conventional Commits，从 `git log <prev-tag>..HEAD --no-merges --format="%s"` 按 commit 类型分组生成 changelog 草稿。展示给用户编辑。

---

### 第 6 步 —— 执行发布

用前面发现的规则，逐步执行：

1. **Bump version** —— 应用到每个版本来源文件。
2. **跑测试** —— 执行测试门命令。
3. **Commit** —— `git add <version files> CHANGELOG.md` 并以 `chore(release): bump version to vX.Y.Z` 提交。
4. **Tag** —— `git tag -a vX.Y.Z -m "vX.Y.Z"`（注释 tag 优于 lightweight tag）。
5. **Push** —— `git push origin <branch> && git push origin vX.Y.Z`。
6. **CI 接管** —— 如果触发是 tag push，提醒用户 CI 会处理剩下的（发布、GitHub release 创建）。展示预期的 CI workflow 文件。
7. **手动发布** —— 如果没有 CI 自动化，列出手动发布命令（例如 `npm publish --access public`、`twine upload dist/*`）。

---

### 第 7 步 —— 首次配置建议

如果第 1f 步发现了缺口，给出具体帮助：

**没有发布 workflow：**
> 你的仓库没有发布 CI workflow。最常见的最佳实践是用一个由 `v*` tag push 触发的 GitHub Actions workflow，它可以：
> - 跑测试
> - 发布到 npm / PyPI 等
> - 用你的发布说明创建 GitHub Release
>
> 要我为你的技术栈生成一份 `.github/workflows/release.yml` 吗？

**没有 git tag：**
> 这看起来是首次发布。git tag 让 GitHub、npm 与其他工具理解版本历史。第 6 步会创建你的第一个 tag。

**构建产物没 gitignore：**
> 构建产物出现在 git 历史或没被 gitignore。这会让仓库膨胀并制造合并冲突。要我加进 `.gitignore` 吗？

---

### 第 8 步 —— 验证

push 之后：
- 看 CI 状态：`gh run list --workflow=<release workflow> --limit=3`（如有 `gh`）。
- 几分钟后到 registry（npm、PyPI）看新版本是否就位。
- 确认 GitHub Release 已创建：`gh release view vX.Y.Z`。

报告成功或标出任何失败。

---

## 备注

- 本 skill **不**硬编码任何项目特定的版本文件或命令。所有内容都从仓库检视中推导。
- `.omk/RELEASE_RULE.md` 是本地缓存。如果你想把推导出的规则分享给团队，把它提交到仓库；如果你想让它保留在本地，加进 `.gitignore`。
- 对于复杂 monorepo 或多包 workspace，本 skill 会检测 workspace 模式（npm workspaces、pnpm workspaces、Cargo workspace）并相应适配。
