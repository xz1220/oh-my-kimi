---
name: doctor
description: 诊断并修复 Kimi CLI 上的 oh-my-kimi 安装（skills、hooks、wrapper、MCP）。
argument-hint: "[--fix] [--verbose]"
---

# Doctor

对本机的 `oh-my-kimi` 安装做一次结构化健康检查，并为每个发现的问题给出具体的修复命令。下列情况使用：

- `/skill:<name>` 调用提示 "skill not found"，但你确信它装过。
- `kimi-omk` 启动报错。
- 某个 hook 不触发（没有 `.env` 块、没有自动格式化等）。
- `kimi info` 报告 `Invalid TOML in configuration file …`。
- 你想在真正干活前验证一台新机器。

## 不要在以下情况使用

- 诊断 Kimi CLI 本身（模型错误、登录、API key）—— 这归上游 Kimi CLI，不在该 skill 范围。
- 诊断主机 OS 的网络 / DNS / TLS —— 超出范围。
- 诊断 skill **内容**质量 —— 改用对应工作流 skill（例如 `/skill:critic`）。

## 这个 skill 检查什么

`install.sh` 实际做的 7 件事 —— 按相同顺序 —— 这样某项失败就直接指向是哪一步坏了或被人手动回退：

| # | Check | What it verifies |
|---|---|---|
| 1 | Kimi CLI on `PATH` | `kimi` binary exists; version ≥ 1.37 |
| 2 | `~/.oh-my-kimi/` layout | Repo snapshot was copied (agents/, skills/, hooks/, scripts/) |
| 3 | Skill symlinks in `~/.kimi/skills/` | Each shipped skill is symlinked to `~/.oh-my-kimi/skills/<name>` |
| 4 | `~/.local/bin/kimi-omk` wrapper | Exists, executable, points at `oh-my-kimi.yaml` |
| 5 | Managed hook block in `~/.kimi/config.toml` | Single `# >>> oh-my-kimi >>>` … `# <<< oh-my-kimi <<<` block; TOML parses cleanly |
| 6 | Hook scripts executable | Every `~/.oh-my-kimi/hooks/*.sh` is `+x` |
| 7 | (Optional) MCP servers | `kimi mcp list` shows the recommended servers if `--with-mcp` ran |

通过的一行打印 `✅`；任何失败打印 `❌` 加一行修复命令。

## 流程

按顺序走完下面的检查。在跑任何会改 `~/.oh-my-kimi/` 之外状态的 `--fix` 动作前，先问用户（特别是：编辑 `~/.kimi/config.toml`、删用户自有 symlink、重跑 `install.sh`）。

### Check 1 — Kimi CLI on PATH

```bash
command -v kimi >/dev/null 2>&1 \
  && kimi --version
```

预期输出：`kimi 1.37.0` 或更高。低于这个版本意味着缺失（Agent 工具、SubagentStart hook、MCP）等多条 shipped skill 所依赖的原语。

修复：按 `https://github.com/MoonshotAI/kimi-cli` 装或升级 Kimi CLI。**不要**用 alias 或 shim 把 `kimi` 指到别的二进制 —— `kimi-omk` 运行时会从 `PATH` 解析真正的 `kimi`。

### Check 2 — 安装目录布局

```bash
test -d ~/.oh-my-kimi \
  && test -f ~/.oh-my-kimi/agents/oh-my-kimi.yaml \
  && test -d ~/.oh-my-kimi/skills \
  && test -d ~/.oh-my-kimi/hooks \
  && test -x ~/.oh-my-kimi/scripts/install.sh \
  && echo "layout OK"
```

任一行失败：用户移动或部分删除了安装。从任意 checkout 跑 `bash ~/.oh-my-kimi/scripts/install.sh`，**或**重新 clone：

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
```

### Check 3 — skill 软链接

```bash
expected=$(ls -d ~/.oh-my-kimi/skills/*/ | wc -l)
actual=$(find ~/.kimi/skills -maxdepth 1 -type l \
  -lname '*.oh-my-kimi/skills/*' 2>/dev/null | wc -l)
echo "expected=$expected installed=$actual"
```

期望 `installed == expected`。不匹配通常意味着：

- `install.sh` 看到同名的预存非 `oh-my-kimi` skill 而跳过了它（在安装日志里找 `[oh-my-kimi] warning: skipping existing non-oh-my-kimi skill: …`）。自行决定保留你的版本还是让 `oh-my-kimi` 占该位。
- 用户手动移动 `~/.kimi/skills/` 或删了软链接。

修复（幂等 —— 可安全重跑）：

```bash
bash ~/.oh-my-kimi/scripts/install.sh
```

强制替换冲突 skill：

```bash
OMK_FORCE=1 bash ~/.oh-my-kimi/scripts/install.sh
```

查看单个坏槽位：

```bash
ls -l ~/.kimi/skills/<name>            # is it a symlink? where to?
readlink ~/.kimi/skills/<name>          # target path
```

### Check 4 — `kimi-omk` wrapper

```bash
test -x ~/.local/bin/kimi-omk \
  && grep -q "$HOME/.oh-my-kimi/agents/oh-my-kimi.yaml" \
       ~/.local/bin/kimi-omk \
  && echo "wrapper OK"
```

wrapper 是个 2 行 bash 脚本。若缺失或指向别处，是用户（或其他工具）把它覆盖了。

修复：重跑 `install.sh`。wrapper 会被安全覆盖。

同时确认 `~/.local/bin` 在 `PATH` 上：

```bash
case ":$PATH:" in *":$HOME/.local/bin:"*) echo "PATH OK" ;;
  *) echo "add $HOME/.local/bin to PATH" ;;
esac
```

### Check 5 — 受管 hook 块 + TOML 合法性

这是修在 commit `a62af4b` 的安装 bug 兜的检查：Kimi 默认配置带一行 inline 数组 `hooks = []`，在它后面追加 `[[hooks]]` array-of-tables 块会产生 `Invalid TOML: Key "hooks" already exists`。

```bash
config=~/.kimi/config.toml
block_count=$(grep -c '^# >>> oh-my-kimi >>>$' "$config" 2>/dev/null || echo 0)
echo "managed blocks: $block_count (expect 1)"
python3 - <<PY
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
text = open("$config","rb").read()
try:
    parsed = tomllib.loads(text.decode())
except Exception as e:
    print("TOML PARSE ERROR:", e); sys.exit(1)
hooks = parsed.get("hooks")
print("hooks keytype:", type(hooks).__name__)
print("hooks count:", len(hooks) if isinstance(hooks, list) else "n/a")
PY
```

期望：

- `managed blocks: 1`
- `hooks keytype: list`
- `hooks count: ≥3`（auto-format、protect-env、notify-on-stop ± stop-guard）

失败模式：

- `managed blocks: 0` —— hooks 被剥离或未安装。跑 `bash ~/.oh-my-kimi/scripts/install.sh`。
- `managed blocks: 2+` —— 重复注入（少见；有人改动了 markers 时会发生）。跑 `bash ~/.oh-my-kimi/scripts/uninstall.sh` 再重装。
- `TOML PARSE ERROR: Key 'hooks' already exists` —— Kimi 默认配置里的 inline `hooks = []` 行没被清除。commit `a62af4b` 起的 install.sh 自动修复；升级安装：

  ```bash
  cd ~/.oh-my-kimi && git pull
  bash scripts/install.sh
  ```

  不重装的一次性手工修复：

  ```bash
  sed -i.before-fix '/^hooks = \[\]$/d' ~/.kimi/config.toml
  ```

### Check 6 — hook 脚本可执行

```bash
for sh in ~/.oh-my-kimi/hooks/*.sh; do
  test -x "$sh" || echo "NOT EXECUTABLE: $sh"
done
```

任一行打印：安装 tar 丢了执行位（少见）。修复：

```bash
chmod +x ~/.oh-my-kimi/hooks/*.sh
```

### Check 7 —（可选）MCP servers

仅当用户用 `--with-mcp` 安装或期望 MCP 支持时才跑。

```bash
kimi mcp list 2>/dev/null | grep -E 'context7|chrome-devtools|sequential-thinking'
```

期望：通过 `mcp/add-recommended-all.sh` 安装时有三行（每个 server 一行）。缺失的 server 可逐个添加：

```bash
bash ~/.oh-my-kimi/mcp/add-context7.sh
bash ~/.oh-my-kimi/mcp/add-chrome-devtools.sh
bash ~/.oh-my-kimi/mcp/add-sequential-thinking.sh
```

## 跨 host 可见性（informational）

Kimi CLI 的默认配置（`merge_all_available_skills = true`）会从以下所有根读 skill：

```
~/.kimi/skills/        ← canonical (oh-my-kimi installs here)
~/.claude/skills/      ← also read by Kimi
~/.codex/skills/       ← also read by Kimi
~/.config/agents/skills/
~/.agents/skills/
```

这意味着 `~/.kimi/skills/` 下安装的 oh-my-kimi 在 Claude Code 与 Codex CLI 会话里也自动可见，**无需**额外设置（前提是它们对应的 host 也用 canonical skill 布局）。如果 `kimi /skill` 里出现重复 skill，检查 `~/.claude/skills/<name>` 或 `~/.codex/skills/<name>` 是不是有旧拷贝、不是 oh-my-kimi 装的。

## 汇报

以一份简明 markdown 报告结束：

```
## oh-my-kimi doctor — <date>

| # | Check                          | Result |
|---|--------------------------------|--------|
| 1 | Kimi CLI on PATH               | ✅ kimi 1.37.0 |
| 2 | Install dir layout             | ✅ |
| 3 | Skill symlinks (36/36)         | ✅ |
| 4 | kimi-omk wrapper               | ✅ |
| 5 | Managed hook block + TOML      | ✅ 1 block, 4 hooks |
| 6 | Hook scripts +x                | ✅ |
| 7 | MCP servers                    | ⚠ context7 missing |

Fixes applied: <list>  ← only if --fix was passed
Suggested next steps: <list>
```

## 工具使用

- 每项检查都用 `Shell`；把输出汇入报告。
- 优先跑不变更的诊断；只有在说明清楚要改什么之后再跑修复。
- 永远不要直接重写 `~/.kimi/config.toml` —— 始终重跑 `install.sh`，它会保留用户非受管行，并做时间戳备份。

## 最终检查表

- [ ] 每项检查都有 ✅ 或显式的 ❌ + 修复命令。
- [ ] 报告显式列出任何被改动的文件。
- [ ] 没传 `--fix` 时，不写任何文件。
- [ ] 如果用户想回滚任一改动，提及备份路径（`*.omk-backup-*`）。
