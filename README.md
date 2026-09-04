# merry

自用的 Surge / Clash 分流规则集。`Surge/` 是唯一手工维护的源，`Clash/` 由 GitHub Actions 自动生成，不要手改。

## 规则清单

| 清单 | 用途 | 建议策略 |
|---|---|---|
| [AI](Surge/AI.list) | 主流海外 AI 服务全集：ChatGPT、Claude、Gemini、Copilot、Cursor、OpenHands、Together 等 | 代理 |
| [AI-Google](Surge/AI-Google.list) | AI 的 Google 子集：Gemini、AI Studio、NotebookLM、Jules、Antigravity、Vertex AI | 单独指定 Google 出口时使用 |
| [MCP](Surge/MCP.list) | 常见远程 MCP 服务的 host：Figma、Notion、Linear、Sentry、Cloudflare 等 | 代理 |
| [Web3](Surge/Web3.list) | 钱包与链上服务：MetaMask、Phantom 等 | 代理 |
| [Broker](Surge/Broker.list) | 券商：富途 / moomoo、长桥、老虎、嘉信 | 按需 |
| [HSBC](Surge/HSBC.list) | 汇丰全球站点，每日从 [KIDA-MNESIA/gadgets](https://github.com/KIDA-MNESIA/gadgets) 同步 | 按需 |
| [HSBC-CN](Surge/HSBC-CN.list) | 汇丰中国站点，同上自动同步 | 直连 |
| [DoubaoInput](Surge/DoubaoInput.list) | 豆包语音输入法的联网域名 | 按需 |
| [SogouInput](Surge/SogouInput.list) | 搜狗输入法的联网域名 | 按需 |
| [Security](Surge/Security.list) | 已知钓鱼与供应链投毒域名 | REJECT |

## 使用

### Surge

在 `[Rule]` 里引用 raw 地址。规则自上而下匹配，首个命中即生效，所以子集要放在全集前面：

```
RULE-SET,https://raw.githubusercontent.com/onepiece-studio/merry/main/Surge/AI-Google.list,Google
RULE-SET,https://raw.githubusercontent.com/onepiece-studio/merry/main/Surge/AI.list,AI
RULE-SET,https://raw.githubusercontent.com/onepiece-studio/merry/main/Surge/MCP.list,Proxy
RULE-SET,https://raw.githubusercontent.com/onepiece-studio/merry/main/Surge/Security.list,REJECT
```

不需要单独控制 Google 出口时，只引用 AI 一条即可，它已经包含 Google 全部条目。

前置 AI-Google 后，Google 全家共用的 `oauth2.googleapis.com` 与 `apis.google.com` 也会跟着 Google 出口走。这是有意为之：Gemini 与 Antigravity 登录依赖它们，Surge 对 HTTPS 无法按路径拆分，而让它们与其余 Google 账号流量同节点更稳。

### Clash / Mihomo

`Clash/` 目录下是同名 `.yaml`，按 `rule-providers` 引用：

```yaml
rule-providers:
  AI:
    type: http
    behavior: classical
    format: yaml
    url: https://raw.githubusercontent.com/onepiece-studio/merry/main/Clash/AI.yaml
    path: ./ruleset/AI.yaml
    interval: 86400

rules:
  - RULE-SET,AI,AI
```

## 收录标准

以 AI 清单为例，其余清单同理：

- 只收该服务自身使用的域名。国内厂商不收，直连即可。
- 只收主流服务。小众或热度已退的不收，纯本地工具没有自己的服务器，也无需收录。
- 多个服务共用、无法在 host 层面拆开的基础设施，只在它服务于主流目标服务时整域保留，否则收窄到精确 host 或删除。
- 完整 host 用 `DOMAIN`，多子域用 `DOMAIN-SUFFIX`，只有形如 `{region}-aiplatform.googleapis.com` 这类前缀主机才用 `DOMAIN-KEYWORD`。

## 目录

```
Surge/      规则源文件，手工维护
Clash/      由 Scripts/convert.sh 生成，CI 自动提交
Scripts/    转换脚本
.github/    convert.yml 在 Surge 变更后生成 Clash；syncHSBC.yml 每日同步汇丰清单
```

本地验证转换：

```bash
bash Scripts/convert.sh
```
