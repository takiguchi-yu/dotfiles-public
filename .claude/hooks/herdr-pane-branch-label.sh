#!/usr/bin/env bash
# Herdr のペイン枠線に「色マーカー + ブランチ名」を出す。
#
# 並んだペインがどれも同じリポジトリだと枠線だけでは見分けが付かないので、
# どのペインがどのブランチの作業かを一目で分かるようにする。Herdr 0.8.2 には
# ペイン単位の色設定が無いため、色を出せる唯一の手段としてラベル先頭に絵文字を置く。
# 色はブランチ名のハッシュで 6 色から選ぶので、同じブランチなら常に同じ色になる。
#
# SessionStart と UserPromptSubmit の両方から呼ぶ。前者だけだとセッション中に
# git switch した後のラベルが古いまま残るため、発言ごとに現在のブランチへ追従させる。
# どちらのイベントも stdout がコンテキストに混ざるので、何も出力しない。
# 判定できない場合は素通り（fail-open）。
#
# bash 必須。zsh は配列が 1 始まりなので markers[0] が空になり、色が出ない。
set -u

exec 2>/dev/null

[ "${HERDR_ENV:-}" = 1 ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

# cwd はイベントの stdin から取る。jq が無い環境やフィールドが無い場合は $PWD に落とす
cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(jq -r '.cwd // empty' <<<"$(cat 2>/dev/null || true)" 2>/dev/null)"
fi
[ -n "$cwd" ] || cwd="$PWD"
[ -d "$cwd" ] || exit 0

# git 管理外のペインには触らない。ラベルを消すと手で付けた名前まで奪うため、残す方に倒す
git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# detached HEAD ではブランチ名が空になるので、短縮 SHA を代わりに出す
branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
if [ -z "$branch" ]; then
  branch="@$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"
  [ "$branch" != "@" ] || exit 0
fi

markers=(🔴 🟠 🟡 🟢 🔵 🟣)
sum="$(printf '%s' "$branch" | cksum | cut -d' ' -f1)"
label="${markers[$((sum % ${#markers[@]}))]} $branch"

# 毎プロンプトで同じ値を書き直すとペインの revision が上がり続けるので、変化時だけ書く
if command -v jq >/dev/null 2>&1; then
  current="$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.pane.label // empty' 2>/dev/null)"
  [ "$current" = "$label" ] && exit 0
fi

herdr pane rename "$HERDR_PANE_ID" "$label" >/dev/null 2>&1
exit 0
