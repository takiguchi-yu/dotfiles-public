---
applyTo: '**'
---

# General Rules

- Code only, no explanation.
- Keep responses concise.
- Omit conversational filler and pleasantries.

# Shell Environment

- The local development shell is `fish`. Always generate terminal commands using fish-compatible syntax.
- Do not use bash- or zsh-specific syntax (for example: `[[... ]]`, `source`, `export VAR=value`, `set -euo pipefail`, or bash arrays).
- Prefer fish forms such as `set -gx VAR value`, `set var value`, and fish-compatible conditionals and substitutions.

# AWS CLI

- **CLIのページャー無効化:** AWS CLIが対話的なページャー（lessなど）を起動して処理が停止するのを防ぐため、必ずコマンドに `--no-cli-pager` オプションを付与するか、事前に `set -gx AWS_PAGER ""` を実行してください。これによりコマンド一発で全結果を出力させてください。
- **リソース操作の制限:** リソースの削除や変更を行うコマンド（`delete-`、`terminate-`、`apply`など）は絶対に実行しないでください。参照系のみ許可します。

<!-- rtk-instructions v2 -->

# RTK — Token-Optimized CLI

**rtk** is a CLI proxy that filters and compresses command outputs, saving 60-90% tokens.

## Rule

Always prefix shell commands with `rtk`:

```bash
# Instead of:              Use:
git status                 rtk git status
git log -10                rtk git log -10
cargo test                 rtk cargo test
docker ps                  rtk docker ps
kubectl get pods           rtk kubectl pods
```

## Meta commands (use directly)

```bash
rtk gain              # Token savings dashboard
rtk gain --history    # Per-command savings history
rtk discover          # Find missed rtk opportunities
rtk proxy <cmd>       # Run raw (no filtering) but track usage
```

<!-- /rtk-instructions -->
