#!/bin/bash
# Claude Code statusline: プロジェクト（ディレクトリ名） / モデル名 / (該当時) 推論エフォート
# レベル / コンテキストウィンドウ使用率 / (該当時) レート制限を表示する。
#
# 端末幅に収まらない場合は詳細度を 1 段落として再構成する。Claude Code はスクリプト実行前に
# COLUMNS / LINES を現在の端末サイズで設定するため（tput cols は使えない）、これを幅の判定に使う。
# https://code.claude.com/docs/en/statusline

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# 「いまどのプロジェクトを開いているか」を示すので、セッション中の cd に影響されない
# project_dir（Claude Code を起動したディレクトリ）を基準にし、無ければ current_dir に落とす。
dir=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // empty')
dir_seg=""
if [ -n "$dir" ]; then
  dir_seg=$(basename "$dir")
fi

if [ -n "$used" ]; then
  ctx=$(printf "Ctx %.0f%%" "$used")
else
  ctx="Ctx --"
fi

# ANSI カラー（ターミナル側でディム表示される想定）
COLOR_DIR="\033[1m"      # bold（前景色を継承するのでライト/ダークどちらのテーマでも読める）
COLOR_MODEL="\033[36m"   # cyan
COLOR_EFFORT="\033[35m"  # magenta
COLOR_CTX="\033[33m"     # yellow
COLOR_5H="\033[32m"      # green
COLOR_7D="\033[34m"      # blue
COLOR_RESET="\033[0m"

# rate_limits は Claude.ai サブスクライバー（Pro/Max）向けで、セッション内の
# 最初のAPIレスポンス後にのみ存在する。five_hour / seven_day はそれぞれ独立に
# 存在しない可能性があるため、jq で // empty を使い、存在しない場合はそのセグ
# メントごと省略する（effort と同じ考え方でプレースホルダーは出さない）。
five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# resets_at（Unixエポック秒）を人間が読める時刻に変換する。
# リセット日が今日でない場合は日付も併記する（macOS/BSD date を使用）。
fmt_resets_at() {
  local epoch="$1"
  local today target
  today=$(date "+%Y-%m-%d")
  target=$(date -r "$epoch" "+%Y-%m-%d" 2>/dev/null)
  if [ "$today" = "$target" ]; then
    date -r "$epoch" "+%H:%M"
  else
    date -r "$epoch" "+%m/%d %H:%M"
  fi
}

# 引数 $1 が 1 のときは resets 時刻まで含めた詳細版、0 のときは使用率だけの短縮版を返す。
rate_seg() {
  local verbose="$1" pct_raw="$2" resets="$3" label="$4"
  [ -n "$pct_raw" ] || return 0
  local pct
  pct=$(printf "%.0f" "$pct_raw")
  if [ "$verbose" = "1" ] && [ -n "$resets" ]; then
    printf "%s:%s%% (resets %s)" "$label" "$pct" "$(fmt_resets_at "$resets")"
  else
    printf "%s:%s%%" "$label" "$pct"
  fi
}

# 表示可能な幅を測るため ANSI エスケープを除去した文字数を返す。
visible_len() {
  local stripped
  stripped=$(printf "%b" "$1" | sed -E $'s/\033\\[[0-9;]*m//g')
  printf "%s" "${#stripped}"
}

# 引数 $1 が 1 のときは詳細版、0 のときは短縮版の 1 行を組み立てる。
build_line() {
  local verbose="$1" line="" five_seg week_seg
  [ -n "$dir_seg" ] && line="${COLOR_DIR}${dir_seg}${COLOR_RESET} | "
  line="${line}${COLOR_MODEL}${model}${COLOR_RESET}"
  # effort（推論エフォートレベル）はモデルが対応していない場合フィールド自体が
  # 存在しないため、その場合はセグメントごと省略しプレースホルダーは出さない。
  [ -n "$effort" ] && line="${line} | ${COLOR_EFFORT}Effort:${effort}${COLOR_RESET}"
  line="${line} | ${COLOR_CTX}${ctx}${COLOR_RESET}"

  five_seg=$(rate_seg "$verbose" "$five_used" "$five_resets" "5h")
  week_seg=$(rate_seg "$verbose" "$week_used" "$week_resets" "7d")
  [ -n "$five_seg" ] && line="${line} | ${COLOR_5H}${five_seg}${COLOR_RESET}"
  [ -n "$week_seg" ] && line="${line} | ${COLOR_7D}${week_seg}${COLOR_RESET}"

  printf "%s" "$line"
}

line=$(build_line 1)
cols="${COLUMNS:-80}"
if [ "$(visible_len "$line")" -gt "$cols" ]; then
  line=$(build_line 0)
fi

printf "%b\n" "$line"
