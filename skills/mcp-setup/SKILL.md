---
name: mcp-setup
description: 配置常用 MCP 服务器以增强 agent 能力
level: 2
---

# MCP Setup

通过 `claude mcp add` 命令行接口，配置 Model Context Protocol（MCP）服务器，扩展 Kimi CLI 的能力，引入网页搜索、文件系统访问、GitHub 集成等外部工具。

## 概览

MCP 服务器为 Kimi CLI agent 提供额外工具。本 skill 帮你用 `claude mcp add` 配置常用 MCP 服务器。

## Step 1：选择安装路径

用 **AskUserQuestion**，**每次只问一个问题**，**每问不超过 3 个选项**。新版 Kimi CLI 会因更大的选项 payload 报无效工具参数，所以把 MCP 选择流分步走。

### Step 1.1：第一层菜单

**Question:** "What kind of MCP setup would you like?"

**Options:**
1. **Recommended starter setup** - Fast path for the most common oh-my-kimi MCP additions
2. **Individual popular server** - Pick one built-in server from a short follow-up menu
3. **Custom server** - Add your own stdio or HTTP MCP server

### Step 1.2：用户选 "Recommended starter setup"

追问一个 **AskUserQuestion**：

**Question:** "Which recommended MCP bundle should I configure?"

**Options:**
1. **Context7 only (Recommended)** - Zero-config docs/context server
2. **Context7 + Exa** - Docs/context plus enhanced web search
3. **Full recommended bundle** - Context7, Exa, Filesystem, and GitHub

把选择映射到要配置的服务器清单。

### Step 1.3：用户选 "Individual popular server"

追问一个 **AskUserQuestion**：

**Question:** "Which server should I configure first?"

**Options:**
1. **Context7 (Recommended)** - Documentation and code context from popular libraries
2. **Exa Web Search** - Enhanced web search (replaces built-in websearch)
3. **More server choices** - Filesystem, GitHub, or the full recommended bundle

若用户选 **More server choices**，再问一个 **AskUserQuestion**：

**Question:** "Which additional MCP option do you want?"

**Options:**
1. **Filesystem (Recommended)** - Extended file system access with additional capabilities
2. **GitHub** - GitHub API integration for issues, PRs, and repository management
3. **Full recommended bundle** - Configure Context7, Exa, Filesystem, and GitHub together

### Step 1.4：用户选 "Custom server"

直接跳到下面的 **Custom MCP Server** 段。

## Step 2：收集必要信息

### Context7：
不需要 API key，立即可用。

### Exa Web Search：
索取 API key：
```
Do you have an Exa API key?
- Get one at: https://exa.ai
- Enter your API key, or type 'skip' to configure later
```

### Filesystem：
询问允许访问的目录：
```
Which directories should the filesystem MCP have access to?
Default: Current working directory
Enter comma-separated paths, or press Enter for default
```

### GitHub：
索取 token：
```
Do you have a GitHub Personal Access Token?
- Create one at: https://github.com/settings/tokens
- Recommended scopes: repo, read:org
- Enter your token, or type 'skip' to configure later
```

## Step 3：通过 CLI 添加 MCP 服务器

用 `claude mcp add` 命令配置每个 MCP 服务器。CLI 会自动处理 settings.json 的更新与合并。

### Context7 配置：
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

### Exa Web Search 配置：
```bash
claude mcp add -e EXA_API_KEY=<user-provided-key> exa -- npx -y exa-mcp-server
```

### Filesystem 配置：
```bash
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem <allowed-directories>
```

### GitHub 配置：

**Option 1：Docker（本地）**
```bash
claude mcp add -e GITHUB_PERSONAL_ACCESS_TOKEN=<user-provided-token> github -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
```

**Option 2：HTTP（远程）**
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

> 注：Docker 选项需要装 Docker。HTTP 选项更简单，但能力可能有差异。

## Step 4：验证安装

配置完成后验证 MCP 服务器是否就绪：

```bash
# List configured MCP servers
claude mcp list
```

这会展示所有已配置的 MCP 服务器及其状态。

## Step 5：展示完成消息

```
MCP Server Configuration Complete!

CONFIGURED SERVERS:
[List the servers that were configured]

NEXT STEPS:
1. Restart Kimi CLI for changes to take effect
2. The configured MCP tools will be available to all agents
3. Run `claude mcp list` to verify configuration

USAGE TIPS:
- Context7: Ask about library documentation (e.g., "How do I use React hooks?")
- Exa: Use for web searches (e.g., "Search the web for latest TypeScript features")
- Filesystem: Extended file operations beyond the working directory
- GitHub: Interact with GitHub repos, issues, and PRs

TROUBLESHOOTING:
- If MCP servers don't appear, run `claude mcp list` to check status
- Ensure you have Node.js 18+ installed for npx-based servers
- For GitHub Docker option, ensure Docker is installed and running
- Run /oh-my-kimi:omc-doctor to diagnose issues

MANAGING MCP SERVERS:
- Add more servers: /oh-my-kimi:mcp-setup or `claude mcp add ...`
- List servers: `claude mcp list`
- Remove a server: `claude mcp remove <server-name>`
```

## 自定义 MCP 服务器

当用户选 "Custom" 时：

询问：
1. 服务器名（标识符）
2. 传输类型：`stdio`（默认）或 `http`
3. stdio：命令与参数（例如 `npx my-mcp-server`）
4. http：URL（例如 `https://example.com/mcp`）
5. 环境变量（可选，键值对）
6. HTTP headers（可选，仅 http 传输）

然后构造并跑对应的 `claude mcp add` 命令：

**stdio 服务器：**
```bash
# Without environment variables
claude mcp add <server-name> -- <command> [args...]

# With environment variables
claude mcp add -e KEY1=value1 -e KEY2=value2 <server-name> -- <command> [args...]
```

**HTTP 服务器：**
```bash
# Basic HTTP server
claude mcp add --transport http <server-name> <url>

# HTTP server with headers
claude mcp add --transport http --header "Authorization: Bearer <token>" <server-name> <url>
```

### Company-context 约定

如果该自定义服务器是为 oh-my-kimi 工作流提供组织级参考材料，建议提供一个名为 `get_company_context` 的工具，并通过 `{ context: string }` 返回 markdown。

本地注册示例：

```bash
claude mcp add company-context -- node examples/vendor-mcp-server/server.mjs
```

然后在 `.claude/omc.jsonc` 或 `~/.config/claude-omc/config.jsonc` 把 oh-my-kimi 指向完整工具名：

```jsonc
{
  "companyContext": {
    "tool": "mcp__company-context__get_company_context",
    "onError": "warn"
  }
}
```

它仍然只是 prompt 中的咨询性上下文，不做运行时强制。

## 常见问题

### MCP 服务器加载不上
- 确保装了 Node.js 18+
- 确保 `npx` 在 PATH 上
- 跑 `claude mcp list` 检查状态
- 看服务器日志找错误

### API key 问题
- Exa：在 https://dashboard.exa.ai 验证 key
- GitHub：确保 token 有需要的 scope（repo、read:org）
- 必要时用正确凭证重跑 `claude mcp add`

### agent 仍在用内置工具
- 配置后重启 Kimi CLI
- 配置了 exa 后内置 websearch 会被降权
- 跑 `claude mcp list` 确认服务器在线

### 删除或更新服务器
- 删除：`claude mcp remove <server-name>`
- 更新：先删旧的，再用新配置加回去
