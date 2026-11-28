# merry

Surge 与 Clash 通用的分流规则集，覆盖 AI 服务、MCP、Web3、Telegram 加密货币、券商、银行、输入法、IP 检测站点、高风险域名和 B 站 PCDN 节点。规则以 Surge 格式维护，Clash / Mihomo 的规则文件由脚本生成。仓库另附按需启用的 Surge 测试模块。

## 分流规则

### 订阅地址

规则订阅使用 jsDelivr CDN，地址前缀如下。

```
https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/
```

如果所在地区无法正常访问 [JSDelivr](https://cdn.jsdelivr.com/), 可使用 [JSDMirror](https://cdn.jsdmirror.com) 代替：

```
https://cdn.jsdmirror.com/gh/onepiece-studio/merry@main/
```

在这个前缀后面接上规则文件路径即可，例如 `Surge/AI.list` 或 `Clash/AI.yaml`。

已有订阅请将文件名中的 `AI-Google` 改为 `GoogleAI`、`Claude` 改为 `Anthropic`，目录和扩展名沿用原值。

| 情况 | 处理方式 |
|---|---|
| 主站偶尔访问异常 | 把域名换成 `fastly.jsdelivr.net`，路径不变 |
| 想拿到刚更新的规则 | CDN 有最多约 12 小时的缓存。改用 GitHub 原始地址 `https://raw.githubusercontent.com/onepiece-studio/merry/main/` 可以立即拿到最新内容，但中国大陆通常无法直连 |

### 规则清单

| 规则 | 用途 | 建议策略 |
|---|---|---|
| [AI](Surge/AI.list) | 主流海外 AI 服务：ChatGPT、Claude、Gemini、Copilot、Cursor、OpenHands、Together 等 | 代理 |
| [OpenAI](Surge/OpenAI.list) | ChatGPT、OpenAI API、CDN、人机验证、高级语音、Azure OpenAI 和 Sora | 需要让 OpenAI 服务单独走一个节点时使用 |
| [GoogleAI](Surge/GoogleAI.list) | AI 规则中的 Google 部分：Gemini、AI Studio、NotebookLM、Jules、Antigravity、Vertex AI | 需要让 Google AI 单独走一个节点时使用 |
| [Anthropic](Surge/Anthropic.list) | AI 规则中的 Anthropic 服务：claude.ai、Claude Code、Anthropic API、MCP 小组件、artifact 分享页 | 需要让 Anthropic 服务单独走一个节点时使用 |
| [MCP](Surge/MCP.list) | 常见远程 MCP 服务：Figma、Notion、Linear、Sentry、Cloudflare 等 | 代理 |
| [Web3](Surge/Web3.list) | 钱包与链上服务：MetaMask、Phantom、Keeper（原 Tonkeeper）、STON.fi、Getgems 等 | 代理 |
| [TelegramCrypto](Surge/TelegramCrypto.list) | Telegram 生态的加密货币服务：内置钱包 Money、Fragment、TON 官方、Walt（原 Wallet in Telegram） | 跟 Telegram 同一出口 |
| [Broker](Surge/Broker.list) | 券商：富途 / moomoo、长桥、老虎、嘉信 | 按需 |
| [HSBC](Surge/HSBC.list) | 汇丰全球站点，每日从 [KIDA-MNESIA/gadgets](https://github.com/KIDA-MNESIA/gadgets) 同步 | 按需 |
| [HSBC-CN](Surge/HSBC-CN.list) | 汇丰中国站点，同上自动同步 | 直连 |
| [StandardChartered](Surge/StandardChartered.list) | 渣打全球站点，每日从 KIDA-MNESIA/gadgets 同步 | 按需 |
| [IBKR](Surge/IBKR.list) | 盈透证券各地区站点，每日从 KIDA-MNESIA/gadgets 同步 | 按需 |
| [Wise](Surge/Wise.list) | Wise 跨境汇款，每日从 KIDA-MNESIA/gadgets 同步 | 按需 |
| [DoubaoInput](Surge/DoubaoInput.list) | 豆包语音输入法的联网域名 | 按需 |
| [SogouInput](Surge/SogouInput.list) | 搜狗输入法的联网域名 | 按需 |
| [IPCheck](Surge/IPCheck.list) | 出口 IP、IP 质量、DNS / WebRTC 泄漏、IPv6、ASN 查询站点：ping0.cc、ip.skk.moe、ipcheck.ing、ip.sb、browserleaks、whoer 等 | 单独的 select 组 |
| [Security](Surge/Security.list) | 已知钓鱼与供应链投毒域名 | REJECT |
| [PCDN](Surge/PCDN.list) | B 站的 PCDN、MCDN 节点与直播 P2P，拒绝后客户端回落正规 CDN | Surge `REJECT-NO-DROP,extended-matching`；Clash Meta / Stash `REJECT` |

Clash 用户把路径中的 `Surge/xxx.list` 换成 `Clash/xxx.yaml` 即可，文件名一一对应。

### Surge

在 `[Rule]` 中引用。Surge 自上而下匹配，命中第一条就停止，所以 OpenAI、GoogleAI 和 Anthropic 要放在 AI 前面。

```
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/OpenAI.list,OpenAI
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/GoogleAI.list,Google
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/Anthropic.list,Claude
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/AI.list,AI
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/MCP.list,Proxy
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/Security.list,REJECT
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/PCDN.list,REJECT-NO-DROP,extended-matching
```

如果这些服务共用 AI 出口，只引用 AI 一条即可，它已经包含 OpenAI、GoogleAI 和 Anthropic 的全部条目。

引用 GoogleAI 后，Google 账号通用的 `oauth2.googleapis.com` 和 `apis.google.com` 也会走 Google 节点。Gemini 和 Antigravity 登录依赖这两个域名，Surge 无法按 URL 路径区分，让它们与其他 Google 账号流量走同一节点也更稳定。

HSBC-CN 要放在 HSBC 之前，顺序反了汇丰中国站点就会走代理。渣打不分中国与全球：渣打中国官网 `www.sc.com/cn/` 与全球站同域名，只按路径区分，按域名拆不开，所以只有一份规则。

IPCheck 要放在所有代理大清单之前，因为 whoer.net、ping0.cc 这类域名也常被通用 Proxy 清单收录。它只收海外站点，ip.cn、ip138.com 这类大陆站不收，它们本就直连，展示的正是「国内视角」，ip.skk.moe 和 ipcheck.ing 调用它们也是为了做国内外对比。STUN 服务器与 Google、YouTube 这类连通性测试目标同样不收，它们是被测对象，走本组会让结果失真。另外 ipinfo.io、ip-api.com、ipify.org 也被不少 App 用来做地理定位，收录后这些请求会跟着本组走，这是品类固有的副作用。

PCDN 要放在所有国内直连 / 媒体规则集之前，例如 blackmatrix7 的 Direct、BiliBili、ChinaMedia 以及 `GEOSITE,CN` / `GEOIP,CN`，因为这些集合包含 bilivideo.com、szbdyd.com 等后缀，顺序反了 PCDN 节点会被直连放行。策略用 `REJECT-NO-DROP`：`REJECT-DROP` 静默丢包，客户端要等超时才回落，起播变慢；普通 `REJECT` 在高频重试下会被 Surge 自动升级为 DROP。`extended-matching` 让规则同时匹配 SNI 与 HTTP Host，App 在 TCP 80 / 443 上直接用 IP 连接时也能命中。收录要求至少两个独立来源确认是 PCDN / P2P，且没有拦截后功能损坏的报告，当前只覆盖 B 站。它只覆盖域名形式的节点，IP:端口形式的 PCDN 和 WebRTC 直连拦不到；`extended-matching` 只在 TCP 80 / 443 上嗅探 SNI 与 HTTP Host，App 直接用 IP 连接非标准端口（如 B 站 MCDN 常用的 4483、8082）或走 QUIC 时同样拦不到，经 Surge DNS 解析、带主机名的连接则不受端口和协议限制；个别地区的个别视频只下发 MCDN 地址时，可能无法播放。

### Clash / Mihomo

通过 `rule-providers` 引用 `Clash/` 目录下的同名文件：

```yaml
rule-providers:
  AI:
    type: http
    behavior: classical
    format: yaml
    url: https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Clash/AI.yaml
    path: ./ruleset/AI.yaml
    interval: 86400

rules:
  - RULE-SET,AI,AI
```

### 收录标准

以下以 AI 规则集为例，说明域名的收录范围和匹配方式。

- 只收该服务自身使用的域名。中国大陆厂商不收，直连即可。
- 只收主流服务。小众或热度已退的不收；纯本地工具没有自己的服务器，也无需收录。
- 多个服务共用、无法按域名拆开的基础设施，只在它服务于主流 AI 服务时整域保留，否则收窄到精确域名或删除。
- 完整域名用 `DOMAIN`，多级子域用 `DOMAIN-SUFFIX`，只有形如 `{region}-aiplatform.googleapis.com` 这类前缀主机才用 `DOMAIN-KEYWORD`。

## Surge 测试模块

[Google One Ultra 焚诀](Surge/Modules/GoogleOneUltra/GoogleOneUltra.sgmodule) 会将 `one.google.com` 加入 Surge 的 MITM 主机列表。启用 MITM 并信任证书后，Surge 可解密该主机的 HTTPS 流量。响应脚本仅匹配 `/ai` 路径，可带查询参数，并会改写响应正文中的套餐标识。

**使用限制与免责声明**（适用于本模块及其配套脚本）

- 仅供在已获相应授权的范围内进行测试。使用者须遵守适用法律法规及相关服务条款。不得用于违法活动或任何商业用途，包括销售、付费分发或提供有偿服务。
- 测试可能改变页面显示的套餐信息。实际订阅权益和费用以服务提供方的订阅记录及账单为准。
- 模块及脚本按现状提供，维护者不保证测试结果准确或功能持续可用。使用者应自行评估测试风险。在适用法律允许的范围内，维护者对因使用本模块或脚本造成的损失不承担责任。

在 Surge iOS 的「模块」中通过下面的 URL 安装并启用。模块会加载远程脚本，响应体上限为 10 MiB。使用 HTTPS 响应脚本需开启脚本和 MITM，并在设备上信任自己的 Surge CA 证书。

```text
https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/Modules/GoogleOneUltra/GoogleOneUltra.sgmodule
```

## 维护

| 路径 | 用途与维护方式 |
|---|---|
| `Surge/*.list` | 分流规则源文件。HSBC、HSBC-CN、StandardChartered、IBKR 和 Wise 每日从上游同步，其余规则手工维护。 |
| `Clash/*.yaml` | [转换脚本](Scripts/convert.sh) 根据同名 Surge 规则集生成。需要调整规则时，修改对应的 `.list` 源文件。 |
| `Surge/Modules/` | 可选的 Surge 模块。每个模块的 `.sgmodule` 配置和配套 JS 放在同一子目录，独立于分流规则转换流程。 |

[同步工作流](.github/workflows/syncUpstream.yml) 每日更新上游规则。[转换工作流](.github/workflows/convert.yml) 在 `main` 收到 `Surge/*.list` 的变更或上游同步成功后运行，并自动提交 `Clash/` 中的变更。

在仓库根目录运行以下命令可重新生成 Clash 规则文件，生成后用 `git diff -- Clash/` 查看差异。

```bash
bash Scripts/convert.sh
```
