# Hooks

oh-my-kimi 完整安装器使用的 Kimi CLI `config.toml` 片段和小型 shell hook。

| Hook | 事件 | 作用 |
|---|---|---|
| `auto-format.{toml,sh}` | `PostToolUse` | 尽力对刚写入或编辑的文件运行 `prettier` / `gofmt` / `black` / `cargo fmt`。失败时放行。 |
| `protect-env.{toml,sh}` | `PreToolUse` | 当路径的 basename 匹配 `.env` 类秘密文件时，阻断（exit 2）`WriteFile` / `StrReplaceFile`。放行 `.example` / `.template` / `.dist` / `.sample` 变体。 |
| `notify-on-stop.{toml,sh}` | `Stop` | 长任务结束时弹桌面通知。可用时使用 `notify-send` / `terminal-notifier`，否则空操作。 |
| `stop-guard.{toml,sh}` | `Stop` | 当 `git status --short` 非空时，提醒 agent 附上最新的验证证据。与 Kimi 的 `--max-ralph-iterations` 搭配使用效果较好，但不直接集成。 |

安装器会在 `~/.kimi/config.toml` 里追加一段托管块：

```bash
bash scripts/install.sh
```

手动安装：

1. 把需要的 `*.toml` 片段复制进 `~/.kimi/config.toml`。
2. 把 `{{OMK_HOME}}` 替换成 checkout 路径，通常是 `~/.oh-my-kimi`。
3. 给对应的 `*.sh` 文件加可执行权限。

除非 hook 明确返回 exit code `2` 或一个 Kimi hook JSON 拒绝对象，否则一律失败时放行。
