# Credits

本仓库整合了自维护配置、规则集、模块脚本和图标资源。这里集中记录外部来源，便于后续审计许可证、更新频率和回滚路径。

## 规则来源

| 来源 | 用途 | 许可证 / 说明 |
| --- | --- | --- |
| [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) | Apple、Google、Microsoft、YouTube、Netflix、Disney、Spotify、TikTok、BiliBili、ChinaMedia、GlobalMedia、Proxy、Game 等规则 | GPL-2.0 |
| [Loyalsoldier/surge-rules](https://github.com/Loyalsoldier/surge-rules) | `ChinaCIDR.list` | GPL-3.0 |
| [VirgilClyne/GetSomeFries](https://github.com/VirgilClyne/GetSomeFries) | `ChinaASN.list`、`TelegramASN.list` | GPL-3.0 |
| [EAlyce/conf](https://github.com/EAlyce/conf) | `AIGC.list` | 以其上游仓库说明为准 |

机器可读的同步来源见 [Rules/sources.json](./Rules/sources.json)。

## 图标来源

| 来源 | 用途 | 说明 |
| --- | --- | --- |
| 本仓库 `Conf/icon/` | 主配置策略组图标 | 当前主线配置优先使用本仓库镜像图标，避免外链失效 |
| [Koolson/Qure](https://github.com/Koolson/Qure) | 部分历史/Alpha 配置图标参考 | 后续若迁移图标，应镜像到本仓库并保留署名 |
| [fmz200/wool_scripts](https://github.com/fmz200/wool_scripts) | 部分历史/Alpha 配置图标参考 | 后续若迁移图标，应镜像到本仓库并保留署名 |
| [Semporia/Hand-Painted-icon](https://github.com/Semporia/Hand-Painted-icon) | 部分历史/Alpha 配置图标参考 | 后续若迁移图标，应镜像到本仓库并保留署名 |

## 脚本和模块参考

| 来源 | 用途 | 说明 |
| --- | --- | --- |
| [sub-store-org/Sub-Store](https://github.com/sub-store-org/Sub-Store) / [Peng-YM/Sub-Store](https://github.com/Peng-YM/Sub-Store) | Sub-Store 本体与同步模块 | 本仓库保留模块入口和使用说明 |

根 README 的“特别感谢”章节列出了历史脚本作者和模块参考来源。

## 许可证说明

本仓库当前没有单独声明整体许可证。继续公开分发前，建议维护者明确：

- 本仓库自写配置、脚本和文档采用什么许可证。
- 第三方规则、图标、脚本是否只做引用、镜像还是二次修改。
- 如果镜像 GPL 来源内容，是否接受对应许可证义务。
