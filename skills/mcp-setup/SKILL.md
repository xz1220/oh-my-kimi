---
name: mcp-setup
description: 配置常用 MCP 服务器以增强 agent 能力
level: 2
---

# MCP 配置

通过 `claude mcp add` 命令行接口，配置 Model Context Protocol（MCP）服务器，扩展 Kimi CLI 的能力，引入网页搜索、文件系统访问、GitHub 集成等外部工具。

## 概览

MCP 服务器为 Kimi CLI agent 提供额外工具。本 skill 帮你用 `claude mcp add` 配置常用 MCP 服务器。

## 步骤 1：选择安装路径

用 **AskUserQuestion**，**每次只问一个问题**，**每问不超过 3 个选项**。新版 Kimi CLI 会因更大的选项 payload 报无效工具参数，所以把 MCP 选择流分步走。

### 步骤 1.1：第一层菜单

**问题：** "你想配置哪种 MCP？"

**选项：**
1. **推荐入门配置** - 快速添加 oh-my-kimi 最常用的 MCP
2. **单个常用服务器** - 从简短的追问菜单里选择一个内置服务器
3. **自定义服务器** - 添加你自己的 stdio 或 HTTP MCP 服务器

### 步骤 1.2：用户选「推荐入门配置」

追问一个 **AskUserQuestion**：

**问题：** "要配置哪套推荐 MCP 组合？"

**选项：**
1. **仅 Context7（推荐）** - 零配置文档 / 上下文服务器
2. **Context7 + Exa** - 文档 / 上下文加增强网页搜索
3. **完整推荐组合** - Context7、Exa、Filesystem 和 GitHub

把选择映射到要配置的服务器清单。

### 步骤 1.3：用户选「单个常用服务器」

追问一个 **AskUserQuestion**：

**问题：** "先配置哪个服务器？"

**选项：**
1. **Context7（推荐）** - 常用库的文档和代码上下文
2. **Exa Web Search** - 增强网页搜索（替代内置 websearch）
3. **更多服务器选项** - Filesystem、GitHub 或完整推荐组合

若用户选 **更多服务器选项**，再问一个 **AskUserQuestion**：

**问题：** "你还想添加哪个 MCP 选项？"

**选项：**
1. **Filesystem（推荐）** - 提供额外能力的扩展文件系统访问
2. **GitHub** - 集成 GitHub API，用于 issue、PR 与仓库管理
3. **完整推荐组合** - 一次性配置 Context7、Exa、Filesystem 和 GitHub

### 步骤 1.4：用户选「自定义服务器」

直接跳到下面的 **自定义 MCP 服务器** 段。

## 步骤 2：收集必要信息

### Context7：
不需要 API key，立即可用。

### Exa Web Search：
索取 API key：
```
你有 Exa API key 吗？
- 可以在这里获取：https://exa.ai
- 输入你的 API key，或输入 'skip' 稍后再配置
```

### Filesystem：
询问允许访问的目录：
```
Filesystem MCP 可以访问哪些目录？
默认：当前工作目录
输入用英文逗号分隔的路径，或直接回车使用默认值
```

### GitHub：
索取 token：
```
你有 GitHub Personal Access Token 吗？
- 可以在这里创建：https://github.com/settings/tokens
- 推荐 scope：repo、read:org
- 输入你的 token，或输入 'skip' 稍后再配置
```

## 步骤 3：通过 CLI 添加 MCP 服务器

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

**方案 1：Docker（本地）**
```bash
claude mcp add -e GITHUB_PERSONAL_ACCESS_TOKEN=<user-provided-token> github -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
```

**方案 2：HTTP（远程）**
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

> 注：Docker 选项需要装 Docker。HTTP 选项更简单，但能力可能有差异。

## 步骤 4：验证安装

配置完成后验证 MCP 服务器是否就绪：

```bash
# 列出已配置的 MCP 服务器
claude mcp list
```

这会展示所有已配置的 MCP 服务器及其状态。

## 步骤 5：展示完成消息

```
MCP 服务器配置完成！

已配置服务器：
[列出本次配置的服务器]

下一步：
1. 重启 Kimi CLI，让配置生效
2. 已配置的 MCP 工具会对所有 agent 可用
3. 运行 `claude mcp list` 验证配置

使用提示：
- Context7：询问库文档（例如："React hooks 怎么用？"）
- Exa：用于网页搜索（例如："搜索最新 TypeScript 特性"）
- Filesystem：执行工作目录之外的扩展文件操作
- GitHub：操作 GitHub 仓库、issue 和 PR

故障排查：
- 如果 MCP 服务器没有出现，运行 `claude mcp list` 检查状态
- 对基于 npx 的服务器，确保已安装 Node.js 18+
- 如果使用 GitHub Docker 方案，确保 Docker 已安装并正在运行
- 运行 /oh-my-kimi:omc-doctor 诊断问题

管理 MCP 服务器：
- 添加更多服务器：/oh-my-kimi:mcp-setup 或 `claude mcp add ...`
- 列出服务器：`claude mcp list`
- 删除服务器：`claude mcp remove <server-name>`
```

## 自定义 MCP 服务器

当用户选「自定义服务器」时：

询问：
1. 服务器名（标识符）
2. 传输类型：`stdio`（默认）或 `http`
3. stdio：命令与参数（例如 `npx my-mcp-server`）
4. http：URL（例如 `https://example.com/mcp`）
5. 环境变量（可选，键值对）
6. HTTP header（可选，仅 http 传输）

然后构造并跑对应的 `claude mcp add` 命令：

**stdio 服务器：**
```bash
# 不带环境变量
claude mcp add <server-name> -- <command> [args...]

# 带环境变量
claude mcp add -e KEY1=value1 -e KEY2=value2 <server-name> -- <command> [args...]
```

**HTTP 服务器：**
```bash
# 基础 HTTP 服务器
claude mcp add --transport http <server-name> <url>

# 带 header 的 HTTP 服务器
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
