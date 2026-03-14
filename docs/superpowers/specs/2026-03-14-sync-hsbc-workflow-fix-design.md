# Sync HSBC Workflow 修复设计

## 问题

`.github/workflows/syncHSBC.yml` 存在两个问题：

1. **命名不一致** — `name: syncHSBC` 使用驼峰命名，而其他 workflow 使用 Title Case（`Convert Surge to Clash`）。应改为 `Sync HSBC Rules`。

2. **未触发下游 workflow** — 同步 HSBC 规则到 `Surge/` 后，`Convert Surge to Clash` workflow 未被触发。根因：GitHub Actions 的默认 `GITHUB_TOKEN` 产生的 push 不会触发其他 workflow（防递归安全机制）。

## 方案

**`workflow_run` 链式触发** — 零配置、无 secret、GitHub 官方推荐模式。

### 改动 1：`syncHSBC.yml` — 修复命名

```yaml
# 改动前
name: syncHSBC

# 改动后
name: Sync HSBC Rules
```

此文件无其他改动。

### 改动 2：`convert.yml` — 添加 `workflow_run` 触发器

在现有触发器列表中添加 `workflow_run`：

```yaml
on:
  push:
    branches: [main]
    paths: ['Surge/*.list']
  workflow_run:
    workflows: ["Sync HSBC Rules"]
    types: [completed]
  workflow_dispatch:
```

在 job 级别添加成功守卫，防止同步失败时也执行转换：

```yaml
jobs:
  convert:
    runs-on: ubuntu-latest
    if: >-
      github.event_name != 'workflow_run' ||
      github.event.workflow_run.conclusion == 'success'
```

checkout 显式指定 `ref: main`，确保 `workflow_run` 触发时能拿到 syncHSBC 刚推送的最新文件（syncHSBC 在运行期间推送了新 commit，但 `workflow_run` 的默认 `github.sha` 可能指向推送前的状态）。这同时改变了 `push`/`workflow_dispatch` 触发器的行为 — 它们将 checkout main 的 HEAD 而非精确的触发 commit — 但对本仓库的规模和使用模式来说无影响：

```yaml
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
```

### 行为矩阵

| 触发方式 | 何时触发 | 条件 |
|---------|---------|------|
| `push` | 手动 push 到 main 且修改了 `Surge/*.list` | 始终运行 |
| `push`（来自 syncHSBC） | syncHSBC 通过 `GITHUB_TOKEN` 推送 | **不会触发** — `GITHUB_TOKEN` 的 push 被 GitHub 设计排除 |
| `workflow_run` | `Sync HSBC Rules` 完成后 | 仅在同步成功时运行 |
| `workflow_dispatch` | 从 GitHub UI 手动触发 | 始终运行 |

### 边界情况

- **同步无变更**：syncHSBC 运行后文件相同，无 commit 推送。`workflow_run` 仍会触发，convert 脚本运行并重新生成 Clash 文件（输出相同），`EndBug/add-and-commit` 无内容可提交。无害，不会产生空 commit。
- **同步失败**：`workflow_run` 以 `conclusion != 'success'` 触发，convert job 被 `if` 守卫跳过。

## 备选方案

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| **A. `workflow_run`（已选）** | 零配置、无 secret、职责分离清晰 | 无文件变更时也会运行（no-op） | 最优权衡 |
| **B. PAT token** | 最"自然" — push 直接触发 path filter | 需要管理 secret、定期轮换 token | 杀鸡用牛刀 |
| **C. 在 syncHSBC 内联转换逻辑** | 单一 workflow，简单 | 转换逻辑分散在两处 | 违反 DRY |

## 部署

两个文件的改动**必须在同一个 commit 中提交**。如果 `convert.yml` 先引用 `"Sync HSBC Rules"` 而 `syncHSBC.yml` 尚未改名，`workflow_run` 触发器将静默失效（不存在该名称的 workflow）。

## 前提假设

- `workflow_run` 仅在触发方 workflow 的定义存在于**默认分支**（main）时才会触发。两个 workflow 均在 main 上运行，满足此条件。
- `workflow_run` 未设 `branches` 过滤器 — 可接受，因为 `syncHSBC.yml` 仅在 main 上运行（cron/dispatch）。

## 变更文件

- `.github/workflows/syncHSBC.yml` — 仅改名
- `.github/workflows/convert.yml` — 触发器 + job 条件 + checkout ref
