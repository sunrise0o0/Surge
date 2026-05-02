# 规则集维护准则

本目录存放 Surge 可直接引用的规则集。大部分文件由 `scripts/update-rules.ps1` 按 `Rules/sources.json` 每日同步生成，少量个性化规则放在 `Rules/Manual/` 后再合并。

## 来源清单

| 来源 | 当前用途 | 接入方式 |
| --- | --- | --- |
| [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) | Apple、Google、Microsoft、流媒体、游戏、GitHub、Proxy 等主规则 | 作为主力上游，按服务拆分后同步 |
| [Loyalsoldier/surge-rules](https://github.com/Loyalsoldier/surge-rules) | `ChinaCIDR.list` | 仅同步中国大陆 CIDR |
| [VirgilClyne/GetSomeFries](https://github.com/VirgilClyne/GetSomeFries) | `ChinaASN.list`、`TelegramASN.list` | 仅同步 ASN 兜底类规则 |
| [EAlyce/conf](https://github.com/EAlyce/conf) | `AIGC.list` | 同步 AI 服务规则，再由本仓库按需要补充 |

机器可读来源以 [sources.json](./sources.json) 为准，并由 [sources.schema.json](./sources.schema.json) 提供编辑器结构提示；许可证和外部资源说明见 [../CREDITS.md](../CREDITS.md)。

## v3.0 分层输出

从 v3.0 开始，部分大规则集会在保留旧 `Rules/*.list` 的同时，额外生成分层文件：

| 目录 | 内容 | 引用方式 |
| --- | --- | --- |
| `Rules/DomainSet/` | 从 `DOMAIN` / `DOMAIN-SUFFIX` 转换而来的纯域名集合 | `DOMAIN-SET` |
| `Rules/NonIP/` | `DOMAIN-KEYWORD`、`URL-REGEX`、`USER-AGENT`、`PROCESS-NAME` 等非 IP 规则 | `RULE-SET` |
| `Rules/IP/` | `IP-CIDR`、`IP-CIDR6`、`IP-ASN`，统一带 `no-resolve` | `RULE-SET,...,no-resolve` |

当前试点：

- `Proxy.list` 同步生成 `DomainSet/Proxy.conf`、`NonIP/Proxy.list`、`IP/Proxy.list`。
- `China.list` 同步生成 `DomainSet/China.conf`、`NonIP/China.list`、`IP/China.list`。

旧 `Rules/*.list` 暂时继续作为主配置引用入口，分层文件先用于测试和后续迁移，避免外部订阅链接突然失效。

## 规则准入

新增上游或新增规则前，先满足这些条件：

- 有明确许可证，允许再分发；新增大批量第三方规则时，在 README 或计划文档中保留来源说明。
- 上游仍在维护，最近更新稳定；不接入长期无人维护、来源不明、只靠复制粘贴堆出来的列表。
- 优先选择 Surge 原生格式；如果需要从 Clash、Quantumult X 等格式转换，必须在计划里写清转换规则和校验方式。
- 上游职责单一，命名可解释；例如 `YouTube`、`Netflix`、`ChinaCIDR` 比混合大包更容易定位问题。
- 默认不直接编辑生成后的 `Rules/*.list`；新增上游改 `Rules/sources.json`，个性化增补写入 `Rules/Manual/*.txt`，排除项写入 `Rules/Manual/*.exclude.txt`。

## 排序原则

Surge 按规则顺序命中，越具体的规则越应该靠前。

建议在 `Conf/Spec/*.conf` 中保持这个顺序：

1. 广告/隐私/安全拦截（默认可注释）。
2. 需要独立策略组的高优先服务，例如 AIGC、Apple、Microsoft、Telegram、游戏。
3. 细分流媒体，例如 YouTube、Netflix、Disney、BiliBili。
4. 广义媒体和 Google 等服务规则。
5. `Proxy.list` 这类大范围代理规则。
6. `China.list`、`RULE-SET,LAN`、`ChinaCIDR.list`。
7. `FINAL`。

同一服务内优先使用 `DOMAIN` / `DOMAIN-SUFFIX`，少用 `DOMAIN-KEYWORD`。IP / ASN 规则只用于域名无法覆盖、服务确实走固定网络段的场景，并保留 `no-resolve`。

## 质量门禁

每次改规则或同步脚本后，至少做这些检查：

- `RULE-SET`、`DOMAIN-SET`、`icon-url` 外链必须是 `https://` 或明确允许的内置值，避免 `ttps://` 这类静默失效。
- 每份 `Conf/Spec/*.conf` 只能有一个 `FINAL`，并且必须是 `[Rule]` 区域最后一条有效规则。
- 每条规则指向的策略组必须在当前配置的 `[Proxy]` 或 `[Proxy Group]` 中存在，Surge 内置策略如 `DIRECT`、`REJECT` 除外。
- `[Proxy Group]` 中引用的子策略组也必须存在，`policy-path` 外部订阅不会被展开校验。
- `# TOTAL:` 必须等于非空、非注释规则行数量。
- 同一文件内不应有完全重复的规则；生成脚本会按顺序保留第一次出现的规则并去掉后续重复。跨文件重复时，要确认是有意用“更靠前规则覆盖更宽规则”。
- `Rules/sources.json` 里的上游 URL 必须能被健康检查访问；如果上游失效，CI 会在生成前失败。
- `type=ip` 的规则集只能包含 `IP-CIDR`、`IP-CIDR6`、`IP-ASN`；`type=domain` 不能混入 IP 规则；未知规则前缀一律失败。
- 所有 `IP-CIDR`、`IP-CIDR6`、`IP-ASN` 规则由生成脚本统一补齐 `no-resolve`，避免因 IP 规则触发不必要 DNS 解析。
- 上游同步报告启用高风险门禁；单个规则集大规模新增、删除、`DOMAIN-KEYWORD` 暴涨或 IP/ASN 暴涨时，CI 会失败并等待人工确认。
- 生成脚本的手工规则优先级、排除规则、大小写去重、分区顺序和 `# TOTAL:` 统计都必须先通过离线测试，再同步真实上游。
- `Rules/Manual/*.exclude.txt` 使用完整规则行或足够精确的关键字，避免误删上游大段内容。
- 新增 `DOMAIN-KEYWORD`、大段 `IP-CIDR`、`IP-ASN` 时，必须写验证理由和回滚方式。
- 改动 `Conf/Spec/*.conf` 后，至少检查主配置、Lite 配置、EN/CN 配置里的策略组名称和规则目标是否一致。

## 手动规则约定

`Rules/Manual/*.txt` 适合放本仓库自己的“小而确定”的补丁：

```text
# 服务或原因
DOMAIN-SUFFIX,example.com
```

`Rules/Manual/*.exclude.txt` 适合排除上游中会误伤本项目默认体验的规则。比如 `Proxy.exclude.txt` 里排除 `DOMAIN-SUFFIX,1password.com`，避免 1Password 被大包代理规则覆盖。

## 变更节奏

- 小修：单个域名补充、明显 typo、误伤排除，可直接改手动规则或配置。
- 中修：新增服务类规则、调整策略组顺序，先写 `docs/` Plan，再执行。
- 大修：切换主上游、合并/拆分大规则集、改变默认直连/代理策略，必须包含来源对比、风险、回滚和验证清单。

## 本地生成

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-rules.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-rule-sources.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-rules.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-rules.ps1 -StrictDuplicates
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\report-rule-changes.ps1
```
