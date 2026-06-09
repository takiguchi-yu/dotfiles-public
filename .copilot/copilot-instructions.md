# General Rules

- Code only, no explanation.

# Shell Environment

- The local development shell is `fish`. Always generate terminal commands using fish-compatible syntax.
- Do not use bash- or zsh-specific syntax (for example: `[[... ]]`, `source`, `export VAR=value`, `set -euo pipefail`, or bash arrays).
- Prefer fish forms such as `set -gx VAR value`, `set var value`, and fish-compatible conditionals and substitutions.

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