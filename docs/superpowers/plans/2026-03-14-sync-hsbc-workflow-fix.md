# Sync HSBC Workflow 修复实施计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 syncHSBC workflow 的命名规范问题，并通过 `workflow_run` 链式触发实现同步后自动转换 Clash 规则。

**Architecture:** 在 `syncHSBC.yml` 中修正 workflow name 为 Title Case；在 `convert.yml` 中添加 `workflow_run` 触发器监听 `Sync HSBC Rules` 的完成事件，附带成功守卫和显式 `ref: main` checkout。

**Tech Stack:** GitHub Actions YAML

**Spec:** `docs/superpowers/specs/2026-03-14-sync-hsbc-workflow-fix-design.md`

---

## Chunk 1: 实施改动

### Task 1: 修改 `syncHSBC.yml` 的 workflow name

**Files:**
- Modify: `.github/workflows/syncHSBC.yml:1`

- [ ] **Step 1: 修改 name 字段**

将第 1 行从：
```yaml
name: syncHSBC
```
改为：
```yaml
name: Sync HSBC Rules
```

无其他改动。

---

### Task 2: 为 `convert.yml` 添加 `workflow_run` 触发器

**Files:**
- Modify: `.github/workflows/convert.yml`

- [ ] **Step 1: 添加 `workflow_run` 触发器**

在 `on:` 块中，`push` 和 `workflow_dispatch` 之间添加 `workflow_run`：

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

- [ ] **Step 2: 添加 job 级别成功守卫**

在 `convert` job 的 `runs-on` 之后添加 `if` 条件：

```yaml
jobs:
  convert:
    runs-on: ubuntu-latest
    if: >-
      github.event_name != 'workflow_run' ||
      github.event.workflow_run.conclusion == 'success'
```

- [ ] **Step 3: checkout 显式指定 `ref: main`**

修改 checkout step：

```yaml
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
```

---

### Task 3: 提交改动

- [ ] **Step 1: 验证最终文件内容**

确认两个文件的完整最终状态：

`.github/workflows/syncHSBC.yml`:
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
      - uses: actions/checkout@v4

      - name: Sync HSBC rules
        run: |
          set -eo pipefail
          curl -fsSL https://raw.githubusercontent.com/KIDA-MNESIA/gadgets/main/geosite/hsbc.list -o Surge/HSBC.list
          curl -fsSL https://raw.githubusercontent.com/KIDA-MNESIA/gadgets/main/geosite/hsbc-cn.list -o Surge/HSBC-CN.list

      - name: Commit changes
        uses: EndBug/add-and-commit@v9
        with:
          default_author: github_actions
          add: 'Surge/'
          message: "chore: sync HSBC rules from KIDA-MNESIA/gadgets"
          push: "origin HEAD:main"
```

`.github/workflows/convert.yml`:
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
      - uses: actions/checkout@v4
        with:
          ref: main

      - name: Convert rules
        run: bash Scripts/convert.sh

      - name: Commit changes
        uses: EndBug/add-and-commit@v9
        with:
          default_author: github_actions
          add: 'Clash/'
          message: "chore: update clash rules"
          push: "origin HEAD:main"
```

- [ ] **Step 2: 在单个 commit 中提交两个文件**

```bash
git add .github/workflows/syncHSBC.yml .github/workflows/convert.yml
git commit -m "fix: rename sync workflow and add workflow_run chaining

- Rename syncHSBC workflow to 'Sync HSBC Rules' (Title Case)
- Add workflow_run trigger to convert.yml for downstream chaining
- Add success guard to skip conversion on sync failure
- Use explicit ref: main for reliable checkout after sync push"
```

**重要：两个文件必须在同一个 commit 中提交。** 如果 `convert.yml` 先引用 `"Sync HSBC Rules"` 而 `syncHSBC.yml` 尚未改名，`workflow_run` 将静默失效。

- [ ] **Step 3: 推送到远端**

```bash
git push origin main
```
