#!/usr/bin/env bash
# 発言ごとに現在時刻を Claude のコンテキストに渡す。
#
# システムプロンプトに入るのは日付だけで、時刻は入らない。長いセッションでは日付も
# 起動時のまま古くなるので、「いま何時か」「前の発言から何分経ったか」を Claude が
# 正しく扱えるよう、UserPromptSubmit の stdout（プレーンテキストはそのままコンテキストに
# 入る）で毎回渡す。https://code.claude.com/docs/en/hooks
set -u

cat >/dev/null 2>&1 || true

printf 'Current time: %s\n' "$(date -Iseconds)"
