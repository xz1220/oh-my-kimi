---
name: wiki
description: LLM Wiki —— 跨会话持续累积的 markdown 知识库（Karpathy 模型）
triggers: ["wiki", "wiki this", "wiki add", "wiki lint", "wiki query"]
---

# Wiki

项目与会话知识的持久化、自维护 markdown 知识库。灵感来自 Karpathy 的 LLM Wiki 概念。

## 操作

### Ingest
把知识处理成 wiki 页面。一次 ingest 可以同时改动多页。

```
wiki_ingest({ title: "Auth Architecture", content: "...", tags: ["auth", "architecture"], category: "architecture" })
```

### Query
按关键词与标签跨所有 wiki 页面搜索。返回匹配的页面与片段 —— 由你（LLM）基于结果综合给出带引用的回答。

```
wiki_query({ query: "authentication", tags: ["auth"], category: "architecture" })
```

### Lint
对 wiki 做健康检查。检测孤页、过时内容、断开的交叉引用、超大页面与结构性矛盾。

```
wiki_lint()
```

### Quick Add
快速添加单页（比 ingest 更简单）。

```
wiki_add({ title: "Page Title", content: "...", tags: ["tag1"], category: "decision" })
```

### List / Read / Delete
```
wiki_list()           # 列出所有页面（读 index.md）
wiki_read({ page: "auth-architecture" })  # 读指定页面
wiki_delete({ page: "outdated-page" })    # 删除页面
```

### Log
通过读 `.omk/wiki/log.md` 查看 wiki 操作历史。

## 分类
按分类组织页面：`architecture`、`decision`、`pattern`、`debugging`、`environment`、`session-log`。

## 存储
- 页面：`.omk/wiki/*.md`（带 YAML frontmatter 的 markdown）
- 索引：`.omk/wiki/index.md`（自动维护的目录）
- 日志：`.omk/wiki/log.md`（追加写入的操作流水）

## 交叉引用
用 `[[page-name]]` 的 wiki 链接语法在页面之间建立交叉引用。

## 自动采集
会话结束时，重要的发现会被自动采集为 session-log 页面。通过 `.omc-config.json` 的 `wiki.autoCapture` 配置（默认开启）。

## 硬性约束
- 不使用向量嵌入 —— query 只用关键词 + 标签匹配
- wiki 页面默认 git-ignored（`.omk/wiki/` 是项目本地）
