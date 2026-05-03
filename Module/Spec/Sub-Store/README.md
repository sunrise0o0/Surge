<h1 align="center">Sub-Store</h1>

<h4 align="center">一个本地的多机场节点整合、修改、自定义模块</h4>

<p align="center">
<img src="https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/img/1.PNG" width="1080"></img>
<img src="https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/img/2.PNG" width="1080"></img>
</p>

## 功能
1. 可以方便的整合单个或多个机场的节点信息
2. 可以容易的对机场节点的名字、排序、筛选等进行修改
3. 可以快捷把整合好的节点信息进行多设备同步
4. 可以在后台定时将Sub-Store的订阅同步至gist

### 同步模块需要配合@Peng-YM大佬的Sub-Store本体模块一起使用
> **稳定版 :** https://raw.githubusercontent.com/Peng-YM/Sub-Store/master/config/Surge.sgmodule<br>

## 使用 Sub-Store
1. 安装Sub-Store模块
2. 开启MitM安装并信任证书。
3. 开启脚本功能开关。
4. 使用 Safari 打开这个 https://sub.store 如网页正常打开并且未弹出任何错误提示，说明 Sub-Store 已经配置成功。
5. 可以把 Sub-Store 添加到主屏幕，即可获得类似于 APP 的使用体验。
6. 更详细的使用指南请参考[文档](https://www.notion.so/Sub-Store-6259586994d34c11a4ced5c406264b46)。

## 节点整理脚本

本项目内置自研 Sub-Store 节点整理脚本：

> https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/Node-Rename.js#provider=TAG&flag&one&keep=GPT+NF+IPLC&blockquic=off

该脚本适合放在 Sub-Store 的“脚本操作”里，用于整理机场订阅节点名。它会识别国家/地区、统一输出命名、补国旗、保留倍率或专线标记，并可统一处理 `block-quic`。多订阅合并时会优先使用每个节点自带的订阅展示名称作为前缀，并兼容 `_subDisplayName`、`subDisplayName`、`subscriptionDisplayName`、`provider`、`subName`、`_subName`、`subscriptionName`、`sourceName`、`subscription.name` 等常见字段；只有节点取不到订阅名称时，才使用 `provider=` / `name=` 参数作为兜底。流量、到期、套餐等信息节点会按订阅名聚合成一条摘要并排在列表最前面，其余真实节点再按地区排序。整理后的节点名默认由“订阅名称 + 地区 + 保留标记 + 序号”组成，例如：

```text
TAG 🇭🇰 香港 IPLC GPT 01
TAG 🇯🇵 日本 2x 01
TAG 🇺🇸 美国 原生 01
花云 (137.51 GB/150 GB / 到期 2026-05-11)
良心-共享 (剩余 4.13 TB / 到期 长期有效)
```

常用模板：

```text
https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/Node-Rename.js#provider=TAG&flag&one&keep=GPT+NF+IPLC&blockquic=off
```

```text
https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/Node-Rename.js#provider=Nexitally&flag&one&clear&blockquic=off
```

```text
https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/Node-Rename.js#provider=TAG&out=en&flag&keep=GPT+NF+IPLC+IEPL&one
```

关键参数：

| 参数 | 作用 |
| --- | --- |
| `provider=TAG` | 兜底服务商名称；节点自带订阅名称存在时优先使用订阅名称 |
| `name=TAG` | `provider=` 的别名 |
| `out=zh/en/flag/quan` | 指定输出国家/地区格式，默认中文 |
| `flag` | 给节点名前添加国旗 |
| `one` | 同一地区只有一个节点时移除 `01` |
| `keep=GPT+NF+IPLC` | 额外保留自定义关键词；支持 `GPT>AI` 这种替换写法 |
| `blkey=GPT+NF+IPLC` | `keep=` 的兼容别名 |
| `clear` | 清理官网、客服、公告等杂项；流量、到期、套餐信息会保留并置顶 |
| `keepUnknown` | 保留无法识别地区的节点 |
| `nm` | `keepUnknown` 的兼容别名 |
| `noSort` | 保持原订阅顺序，不按地区排序 |
| `sep=空格` | 设置名称片段之间的分隔符，默认空格 |
| `sn=空格` | 设置序号前的分隔符，默认空格 |
| `blockquic=on/off` | 批量设置节点的 `block-quic` |

默认会保留这些常见标记：`IPLC`、`IEPL`、`BGP`、`CN2`、`原生`、`商宽`、`Game`、`GPT`、`NF`、`Disney`、`TikTok`、`UDP` 和倍率标记。

## How to use
### 1. 安装环境
**需要有网络调试工具 Surge ，且要付费至具有面板功能**<br>
最低支持版本 :<br>
>**AppStore 版 4.9.3 或更新版本**<br>
>**TestFlight 版 4.11.0 (2014) 或更新版本**

### 2. 模块安装链接
> **凌晨1点开始每6个小时同步 :** https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/6hours.sgmodule<br>
> **早上5点开始每12个小时同步 :** https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/12hours.sgmodule<br>
> **凌晨1点开始每24个小时同步 :** https://raw.githubusercontent.com/Rabbit-Spec/Surge/Master/Module/Spec/Sub-Store/Moore/24hours.sgmodule<br>
通常情况下建议使用「凌晨1点开始每24个小时同步」这个版本。

### 3. 安装方式
打开 Surge -> 模块 -> 安装新模块... -> 复制粘贴上方的安装链接 -> 完成!

### 4. 更新模块方式
**请按照以下步骤更新**<br>
#### 更新模块本身 : 
>Surge -> 模块 -> 找到本模块 -> 左滑后点击更新<br>
#### 更新外部资源 : 
>点击首页最上方打开 Profile 页面 -> 更新外部资源 <br>

**两次更新之间建议 _ 间隔 5 分钟以上_，否则又几率页面缓存文档尚未更新导致更新失败<br>
(检查方式为 Surge -> 脚本 -> 脚本编辑器 -> 载入 -> Sub-Store Sync -> 检查代码是否与网页版本相同**

## 共同作者
**Peng-YM<br>
**Rabbit-Spec<br>

__以上順序不分排名__

## 我用的机场
**我用着好用不代表你用着也好用，如果想要入手的话，建议先买一个月体验一下。任何机场都有跑路的可能。**<br>
> **「Nexitally」:** [佩奇家主站，一家全线中转线路的高端机场，延迟低速度快。](https://naiixi.com/signupbyemail.aspx?MemberCode=0b532ff85dda43e595fb1ae17843ae6d20211110231626) <br>

> **「TAG」:** [目前共有90+个国家地区节点，覆盖范围目前是机场里最广的。](https://tagss04.pro/#/auth/hlnIqYOx)
