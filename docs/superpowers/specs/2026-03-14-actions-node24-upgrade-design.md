# GitHub Actions Node.js 24 升级设计

## 问题

GitHub Actions 警告 `actions/checkout@v4` 和 `EndBug/add-and-commit@v9` 运行在 Node.js 20 上，2026-06-02 起将强制使用 Node.js 24。

## 方案

### 改动 1：`actions/checkout@v4` → `@v6`

两个 workflow 文件均升级。v6 原生支持 Node.js 24，用法无变化。

### 改动 2：`EndBug/add-and-commit@v9` → `stefanzweifel/git-auto-commit-action@v7`

`EndBug/add-and-commit` 目前无 Node.js 24 版本。`stefanzweifel/git-auto-commit-action@v7` 从 v7.0.0 起支持 Node.js 24，2500+ stars，功能等价。

参数映射：

| EndBug/add-and-commit | git-auto-commit-action | 说明 |
|----------------------|----------------------|------|
| `add: 'Surge/'` | `file_pattern: 'Surge/'` | 指定暂存文件 |
| `message: "..."` | `commit_message: "..."` | 提交信息 |
| `default_author: github_actions` | （默认值即可） | 默认 committer 为 `github-actions[bot]`；author 变为触发者（`schedule` 时仍为 bot，`workflow_dispatch` 时为操作人），这是更好的行为 |
| `push: "origin HEAD:main"` | `branch: main` | 推送目标分支 |

**无变更时行为**：`git-auto-commit-action` 会检测 working tree 是否 dirty，无变更时优雅跳过，不报错。与原有行为一致。

### 最终文件状态

**`.github/workflows/syncHSBC.yml`**:

```yaml
name: Sync HSBC Rules

on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  syncHSBC:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Sync HSBC rules
        run: |
          set -eo pipefail
          curl -fsSL https://raw.githubusercontent.com/KIDA-MNESIA/gadgets/main/geosite/hsbc.list -o Surge/HSBC.list
          curl -fsSL https://raw.githubusercontent.com/KIDA-MNESIA/gadgets/main/geosite/hsbc-cn.list -o Surge/HSBC-CN.list

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v7
        with:
          file_pattern: 'Surge/'
          commit_message: "chore: sync HSBC rules from KIDA-MNESIA/gadgets"
          branch: main
```

**`.github/workflows/convert.yml`**:

```yaml
name: Convert Surge to Clash

on:
  push:
    branches: [main]
    paths: ['Surge/*.list']
  workflow_run:
    workflows: ["Sync HSBC Rules"]
    types: [completed]
  workflow_dispatch:

jobs:
  convert:
    runs-on: ubuntu-latest
    if: >-
      github.event_name != 'workflow_run' ||
      github.event.workflow_run.conclusion == 'success'
    steps:
      - uses: actions/checkout@v6
        with:
          ref: main

      - name: Convert rules
        run: bash Scripts/convert.sh

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v7
        with:
          file_pattern: 'Clash/'
          commit_message: "chore: update clash rules"
          branch: main
```

## 验证

部署后通过 GitHub UI 手动触发 `Sync HSBC Rules`（workflow_dispatch），确认：
1. workflow 运行无 Node.js 20 警告
2. commit 正常生成（如有文件变更）
3. `Convert Surge to Clash` 被链式触发

## 变更文件

- `.github/workflows/syncHSBC.yml` — checkout 升级 + commit action 替换
- `.github/workflows/convert.yml` — checkout 升级 + commit action 替换
