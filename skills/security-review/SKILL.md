---
name: security-review
description: 面向密钥、注入、authz/authn、不安全 IO、依赖与数据外泄风险的安全评审
argument-hint: "<diff, file or feature>"
---

# Security Review

检查以下风险：

- 密钥或凭据处理错误。
- 通过 shell、SQL、模板、路径或浏览器 sink 的注入。
- 缺失授权检查。
- 认证边界混淆。
- 不安全的文件写入、归档解压或路径穿越。
- 过度记录个人或敏感数据。
- 本次改动引入的依赖或供应链风险。

只报告有代码或配置证据支撑的合理风险。
