# merry

Surge 与 Clash 通用的分流规则集，覆盖 AI 服务、MCP、Web3、券商、汇丰、输入法和高风险域名。规则以 Surge 格式维护，Clash 格式自动生成，两者内容一致。

## 订阅地址

所有规则通过 jsDelivr CDN 分发，中国大陆可直接访问：

```
https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/
```

在这个前缀后面接上规则文件路径即可，例如 `Surge/AI.list` 或 `Clash/AI.yaml`。

| 情况 | 处理方式 |
|---|---|
| 主站偶尔访问异常 | 把域名换成 `fastly.jsdelivr.net`，路径不变 |
| 想拿到刚更新的规则 | CDN 有最多约 12 小时的缓存。改用 GitHub 原始地址 `https://raw.githubusercontent.com/onepiece-studio/merry/main/` 可以立即拿到最新内容，但中国大陆通常无法直连 |

## 分流规则

| 规则 | 用途 | 建议策略 |
|---|---|---|
| [AI](Surge/AI.list) | 主流海外 AI 服务：ChatGPT、Claude、Gemini、Copilot、Cursor、OpenHands、Together 等 | 代理 |
| [AI-Google](Surge/AI-Google.list) | AI 规则中的 Google 部分：Gemini、AI Studio、NotebookLM、Jules、Antigravity、Vertex AI | 需要让 Google AI 单独走一个节点时使用 |
| [MCP](Surge/MCP.list) | 常见远程 MCP 服务：Figma、Notion、Linear、Sentry、Cloudflare 等 | 代理 |
| [Web3](Surge/Web3.list) | 钱包与链上服务：MetaMask、Phantom 等 | 代理 |
| [Broker](Surge/Broker.list) | 券商：富途 / moomoo、长桥、老虎、嘉信 | 按需 |
| [HSBC](Surge/HSBC.list) | 汇丰全球站点，每日从 [KIDA-MNESIA/gadgets](https://github.com/KIDA-MNESIA/gadgets) 同步 | 按需 |
| [HSBC-CN](Surge/HSBC-CN.list) | 汇丰中国站点，同上自动同步 | 直连 |
| [DoubaoInput](Surge/DoubaoInput.list) | 豆包语音输入法的联网域名 | 按需 |
| [SogouInput](Surge/SogouInput.list) | 搜狗输入法的联网域名 | 按需 |
| [Security](Surge/Security.list) | 已知钓鱼与供应链投毒域名 | REJECT |

Clash 用户把路径中的 `Surge/xxx.list` 换成 `Clash/xxx.yaml` 即可，文件名一一对应。

## Surge

在 `[Rule]` 中引用。Surge 自上而下匹配，命中第一条就停止，所以 AI-Google 要放在 AI 前面：

```
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/AI-Google.list,Google
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/AI.list,AI
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/MCP.list,Proxy
RULE-SET,https://cdn.jsdelivr.net/gh/onepiece-studio/merry@main/Surge/Security.list,REJECT
```

如果不需要把 Google AI 分开，只引用 AI 一条即可，它已经包含 Google 的全部条目。

引用 AI-Google 后，Google 账号通用的 `oauth2.googleapis.com` 和 `apis.google.com` 也会走 Google 节点。Gemini 和 Antigravity 登录依赖这两个域名，Surge 无法按 URL 路径区分，让它们与其他 Google 账号流量走同一节点也更稳定。

## Clash / Mihomo

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

## 收录标准

以 AI 规则为例，其余同理：

- 只收该服务自身使用的域名。中国大陆厂商不收，直连即可。
- 只收主流服务。小众或热度已退的不收；纯本地工具没有自己的服务器，也无需收录。
- 多个服务共用、无法按域名拆开的基础设施，只在它服务于主流 AI 服务时整域保留，否则收窄到精确域名或删除。
- 完整域名用 `DOMAIN`，多级子域用 `DOMAIN-SUFFIX`，只有形如 `{region}-aiplatform.googleapis.com` 这类前缀主机才用 `DOMAIN-KEYWORD`。

## 维护

```
Surge/      规则源文件，手工维护
Clash/      由 Scripts/convert.sh 生成，GitHub Actions 自动提交，不要手改
Scripts/    转换脚本
.github/    convert.yml 在 Surge 变更后生成 Clash；syncHSBC.yml 每日同步汇丰规则
```

本地验证转换：

```bash
bash Scripts/convert.sh
```
