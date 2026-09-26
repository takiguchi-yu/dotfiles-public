#!/bin/bash
# implementer サブエージェント専用ガード。
# feature ブランチへの push は通し、保護ブランチと破壊的操作を拒否する。
# 全体をブロックしたい場合は git-guardrails-claude-code スキルのスクリプトを使う。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

# 破壊的操作は常に拒否する
DESTRUCTIVE=(
  "reset --hard"
  "clean -f"
  "branch -D"
  "checkout \."
  "restore \."
  "push .*--force"
  "push .*-f( |$)"
  "push .*--delete"
)
for pattern in "${DESTRUCTIVE[@]}"; do
  if echo "$COMMAND" | grep -qE "git .*$pattern"; then
    block "'$COMMAND' は破壊的操作です。人間が実行してください。"
  fi
done

# push は保護ブランチのみ拒否する
if echo "$COMMAND" | grep -qE "git +push"; then
  if echo "$COMMAND" | grep -qE "git +push +[^ ]+ +(HEAD:)?(refs/heads/)?(main|master|develop)( |$)"; then
    block "保護ブランチへの push です。feature ブランチに push し、Draft PR の base として指定してください。"
  fi
  if echo "$COMMAND" | grep -qE "git +push *$"; then
    block "push 先を明示してください: git push origin <feature-branch>"
  fi
fi

exit 0
