[![Support on Afdian](https://img.shields.io/badge/Support-爱发电-orange.svg?style=flat-square&logo=afdian)](https://ifdian.net/a/Rabbit-Spec)
<h1 align="center">Surge自用配置以及模块和脚本</h1>

<p align="center">
<img src="https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Conf/img/1.PNG" width="300"></img>
<img src="https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Conf/img/5.PNG" width="300"></img>
</p>

### 配置链接
> **稳定版 :** https://github.com/Rabbit-Spec/Surge/tree/Master/Conf<br>

### 配置选择
| 配置 | 适合场景 | 特点 |
| --- | --- | --- |
| `Conf/Spec/Surge.conf` | 日常主力使用 | 策略组完整，流媒体、AI、Apple、Microsoft、游戏等服务拆分较细 |
| `Conf/Spec/Sunrise-Surge.conf` | 多机场 / Sub-Store 用户 | 使用更完整的地区 Smart Group，适合节点较多的订阅 |
| `Conf/Spec/Surge-Lite-CN.conf` | 中文轻量用户 | 保留核心服务分流，策略组数量较少 |
| `Conf/Spec/Surge-Mini.conf` | 极简用户 | 只保留 AIGC、Apple、媒体、Proxy、China 等核心规则 |
| `Conf/Spec/Surge-EN.conf` / `Surge-Lite-EN.conf` | 英文命名用户 | 策略组使用英文命名，便于跨语言环境维护 |
| `Conf/Spec/Surge-Developer.conf` | 开发调试 | 规则极简，适合临时调试网络行为 |

### 模块链接
> **稳定版 :** https://github.com/Rabbit-Spec/Surge/tree/Master/Module<br>

### 「进阶」分流规则、重写规则及脚本
> **公开版 :** https://github.com/blackmatrix7/ios_rule_script<br>

### 「进阶」解锁完整的Apple功能和集成服务
> **公开版 :** https://github.com/VirgilClyne/iRingo<br>

### 「进阶」Boxjs可以解锁脚本的更多可玩性
> **公开版 :** https://docs.boxjs.app<br>

本仓库之中所有配置/脚本纯属自用备份，请不要fork，自行同步。

---

## ☕ 赞助与支持

如果你觉得 **Rabbit-Spec** 的「Surge自用配置以及模块和脚本」项目对你有帮助，欢迎请我喝杯咖啡。

👉 [点击前往爱发电支持我](https://ifdian.net/a/Rabbit-Spec)

---

## 我用的机场
**我用着好用不代表你用着也好用，如果想要入手的话，建议先买一个月体验一下。任何机场都有跑路的可能。**<br>
> **「Nexitally」:** [佩奇家主站，一家全线中转线路的高端机场，延迟低速度快。](https://nxonearth.com/signupbyemail.aspx?MemberCode=0b532ff85dda43e595fb1ae17843ae6d20211110231626) <br>

> **「TAG」:** [目前共有90+个国家地区节点，覆盖范围目前是机场里最广的。](https://482469.dedicated-afflink.com) <br>

---

# 免责声明
- Rabbit-Spec 本仓库中的任何内容都仅用于资源共享和学习研究，不能保证其合法性，准确性，完整性和有效性，请根据情况自行判断。

- 间接使用本项目内容的任何用户，包括但不限于建立VPS或在某些行为违反国家/地区法律或相关法规的情况下进行传播, Rabbit-Spec 对于由此引起的任何隐私泄漏或其他后果概不负责。

- 请勿将本仓库内的任何内容用于商业或非法目的，否则后果自负。

- 如果任何单位或个人认为该项目的内容可能涉嫌侵犯其权利，则应及时通知并提供身份证明，所有权证明，我将在收到认证文件后删除相关内容。

- Rabbit-Spec 对任何本仓库中包含的脚本在使用中可能出现的问题概不负责，包括但不限于由任何脚本错误导致的任何损失或损害.

- 您必须在下载后的24小时内从计算机或手机中完全删除以上内容。

- 任何以任何方式查看此项目的人或直接或间接使用该项目的任何脚本的使用者都应仔细阅读此声明。Rabbit-Spec 保留随时更改或补充此免责声明的权利。一旦使用并复制了任何本仓库相关脚本或其他内容，则视为您已接受此免责声明。

- ## 关于脚本的补充说明
- 本仓库的部分脚本在各位大佬的此基础上进行修改满足我的需求作为自用库使用，并不负责维护脚本。
- 不保证所有脚本的可用性。

### 特别感谢以下脚本作者以及整合时参考的作者 
- [@Nebulosa-Cat](https://github.com/Nebulosa-Cat)
- [@NobyDa](https://github.com/NobyDa)
- [@LucaLin233](https://github.com/LucaLin233)
- [@Hyseen](https://github.com/Hyseen)
- [@congcong0806](https://github.com/congcong0806)
- [@fishingworld](https://github.com/fishingworld)
- [@mieqq](https://github.com/mieqq)
- [@TributePaulWalker](https://github.com/TributePaulWalker)
### 分流规则、重写规则及脚本维护者
- [@blackmatrix7](https://github.com/blackmatrix7)
### 解锁完整的Apple功能和集成服务维护者
- [@VirgilClyne](https://github.com/VirgilClyne)

### 规则与来源治理
- [规则集维护准则](./Rules/README.md)
- [来源与许可证说明](./CREDITS.md)
- [升级规划文档](./docs/README.md)

### 规则自动化状态
- 规则来源由 `Rules/sources.json` 管理，并由 GitHub Actions 每日同步。
- 生成脚本会合并 `Rules/Manual/*.txt`，应用 `Rules/Manual/*.exclude.txt`，按顺序去重，并为 IP / ASN 规则补齐 `no-resolve`。
- v3.0 起，CI 会额外检查配置中的 `FINAL` 位置、策略组引用、规则统计、重复规则和高风险上游变更。
- `Rules/DomainSet/`、`Rules/NonIP/`、`Rules/IP/` 是试点分层输出；旧 `Rules/*.list` 链接仍保留，避免影响已有订阅。

### 规则说明与使用方法

`Rules/` 目录里的规则可以被 Surge 直接引用。默认推荐继续使用根目录下的 `Rules/*.list`，兼容性最好，也和本仓库主配置保持一致。

常用规则：

| 规则 | 用途 | 推荐策略 |
| --- | --- | --- |
| `AIGC.list` | OpenAI、Claude、Cursor、Gemini 等 AI 服务 | AI / 智能助理策略组 |
| `Apple.list` | Apple 服务 | 直连或 Apple 专用策略组 |
| `Microsoft.list` | Microsoft / GitHub 相关服务 | 直连或 Microsoft 专用策略组 |
| `TelegramASN.list` | Telegram ASN / 域名兜底 | Telegram 专用策略组 |
| `YouTube.list`、`Netflix.list`、`Disney.list` | 细分流媒体 | 对应流媒体策略组 |
| `GlobalMedia.list` | 国外媒体大包 | 国外媒体策略组 |
| `Proxy.list` | 常见代理域名大包 | 默认代理策略组 |
| `China.list`、`ChinaCIDR.list`、`ChinaASN.list` | 国内域名、CIDR、ASN | `DIRECT` / 全球直连 |

在 Surge 配置的 `[Rule]` 里这样引用：

```ini
RULE-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/AIGC.list,📟 智能助理
RULE-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/Proxy.list,✈️ 节点选择
RULE-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/China.list,🌐 全球直连
RULE-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/ChinaCIDR.list,🌐 全球直连
FINAL,✈️ 节点选择,dns-failed
```

规则顺序建议：

1. 需要独立策略组的服务，例如 AIGC、Apple、Microsoft、Telegram、游戏。
2. 细分流媒体，例如 YouTube、Netflix、Disney、BiliBili。
3. `GlobalMedia.list`、`Proxy.list` 这类大范围规则。
4. `China.list`、`LAN`、`ChinaCIDR.list` 这类直连兜底。
5. `FINAL` 放最后。

进阶分层规则目前是试点输出，适合想减少大规则集开销或调试规则命中的用户：

```ini
DOMAIN-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/DomainSet/Proxy.conf,✈️ 节点选择
RULE-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/NonIP/Proxy.list,✈️ 节点选择
RULE-SET,https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Rules/IP/Proxy.list,✈️ 节点选择,no-resolve
```

手工维护规则时不要直接改生成后的 `Rules/*.list`：

- 新增固定补丁：写到 `Rules/Manual/规则名.txt`
- 排除上游误伤：写到 `Rules/Manual/规则名.exclude.txt`
- 新增上游来源：改 `Rules/sources.json`

本地更新和检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-rules.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-rule-sources.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-rules.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-rules.ps1 -StrictDuplicates
```

### (排名不分先后，如有遗漏万分抱歉，请联系我加上）
