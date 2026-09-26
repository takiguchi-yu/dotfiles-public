# shellcheck shell=bash disable=SC2088,SC2016
# （メッセージ中の ~ は表示用、jq のプログラムは展開しない文字列）
# setup.sh / import.sh が共有する処理。単体では実行しない。
# macOS 標準の bash 3.2 で動くように書く（連想配列・mapfile は使わない）。

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINKS_FILE="$DOTFILES_DIR/links.txt"
LOCAL_DIR="$HOME/.config/dotfiles/local"
BACKUP_DIR="$HOME/.local/state/dotfiles/backup/$(date +%Y%m%d-%H%M%S)"
export DOTFILES_DIR

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31mエラー:\033[0m %s\n' "$*" >&2
  exit 1
}

# y/N で確認する。ASSUME_YES=1 なら常に y。
confirm() {
  [ "${ASSUME_YES:-0}" = 1 ] && return 0
  local answer
  read -r -p "$1 [y/N] " answer </dev/tty
  [ "$answer" = y ] || [ "$answer" = Y ]
}

# links.txt を「種類<TAB>ホームのパス<TAB>リポジトリのパス」の行に正規化して出す。
# compose の行は 3 列目がローカル設定名になる。
manifest() {
  local kind a b
  while read -r kind a b; do
    case "$kind" in '' | '#'*) continue ;; esac
    case "$kind" in
      link | each | ignore) printf '%s\t%s\t%s\n' "$kind" "$a" "${b:-$a}" ;;
      compose) printf '%s\t%s\t%s\n' "$kind" "$a" "$b" ;;
      *) die "links.txt の種類が不明です: $kind" ;;
    esac
  done <"$LINKS_FILE"
}

# ホームのパスが取り込みの対象外か。links.txt の ignore と、ローカル設定の import-ignore を見る。
is_ignored() {
  local path="$1" kind pattern _
  while IFS=$'\t' read -r kind pattern _; do
    [ "$kind" = ignore ] || continue
    # shellcheck disable=SC2254
    case "$path" in $pattern) return 0 ;; esac
  done < <(manifest)
  if [ -f "$LOCAL_DIR/import-ignore" ]; then
    while read -r pattern; do
      case "$pattern" in '' | '#'*) continue ;; esac
      # shellcheck disable=SC2254
      case "$path" in $pattern) return 0 ;; esac
    done <"$LOCAL_DIR/import-ignore"
  fi
  return 1
}

# ホームのパスがリポジトリの同じ場所を指すリンクか。
links_to_repo() {
  local home="$HOME/$1" repo="$DOTFILES_DIR/$2"
  [ -L "$home" ] || return 1
  [ "$(cd "$(dirname "$home")" && realpath "$(basename "$home")" 2>/dev/null)" = "$(realpath "$repo")" ]
}

# ホームの実体をバックアップ先に退避する。
evacuate() {
  local rel="$1"
  mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  mv "$HOME/$rel" "$BACKUP_DIR/$rel"
  info "退避しました: ~/$rel -> $BACKUP_DIR/$rel"
}

# --- 合成ファイル -------------------------------------------------------------
# 公開分（リポジトリ）とローカル設定を合成する。オブジェクトは再帰的に重ね、
# 配列はローカル設定の要素を後ろに足し、それ以外はローカル設定の値で上書きする。
JQ_MERGE='
def merge($o):
  if (type == "object") and ($o | type == "object") then
    reduce ($o | keys_unsorted[]) as $k (.;
      if has($k) then .[$k] |= merge($o[$k]) else .[$k] = $o[$k] end)
  elif (type == "array") and ($o | type == "array") then . + ($o - .)
  else $o end;
.[0] | merge($overlay[0])'

# 合成の逆。ホームのファイルからローカル設定が持ち込んだ部分を取り除き、公開分に戻す。
# ローカル設定にあるキーの値は、ホームで変わっていても公開分の値に戻す（秘匿値を持ち出さない）。
JQ_UNMERGE='
def unmerge($o; $b):
  if (type == "object") and ($o | type == "object") then
    reduce ($o | keys_unsorted[]) as $k (.;
      if has($k) | not then .
      else
        ($b | if type == "object" and has($k) then {v: .[$k]} else null end) as $bk
        | .[$k] as $h
        | if ($h | type == "object") and ($o[$k] | type == "object") then
            ($h | unmerge($o[$k]; ($bk.v // {}))) as $r
            | if ($r == {} and $bk == null) then del(.[$k]) else .[$k] = $r end
          elif ($h | type == "array") and ($o[$k] | type == "array") then
            .[$k] = ($h - ($o[$k] - ($bk.v // [])))
            | if (.[$k] == [] and $bk == null) then del(.[$k]) else . end
          elif $bk == null then del(.[$k])
          else .[$k] = $bk.v end
      end)
  else . end;
.[0] | unmerge($overlay[0]; $base[0])'

overlay_file() { # ローカル設定が無ければ空のオブジェクトとして扱う
  if [ -f "$LOCAL_DIR/$1" ]; then echo "$LOCAL_DIR/$1"; else echo /dev/null; fi
}

compose_json() { # <公開分> <ローカル設定名>
  local overlay
  overlay="$(overlay_file "$2")"
  if [ "$overlay" = /dev/null ]; then
    jq . "$1"
  else
    jq -n --slurpfile overlay "$overlay" "[input] | $JQ_MERGE" "$1"
  fi
}

decompose_json() { # <ホームのファイル> <ローカル設定名> <公開分>
  local overlay
  overlay="$(overlay_file "$2")"
  if [ "$overlay" = /dev/null ]; then
    jq . "$1"
  else
    jq -n --slurpfile overlay "$overlay" --slurpfile base "$3" "[input] | $JQ_UNMERGE" "$1"
  fi
}

# ホームの合成ファイルに、まだ取り込んでいない変更があるか。
has_unimported_changes() { # <ホームのパス> <ローカル設定名> <リポジトリのパス>
  local home="$HOME/$1" repo="$DOTFILES_DIR/$1"
  [ -f "$home" ] && [ ! -L "$home" ] || return 1
  ! diff -q <(decompose_json "$home" "$2" "$repo" | jq -S .) <(jq -S . "$repo") >/dev/null
}

compose_all() {
  local kind home name target
  while IFS=$'\t' read -r kind home name; do
    [ "$kind" = compose ] || continue
    target="$HOME/$home"
    if has_unimported_changes "$home" "$name"; then
      warn "~/$home に取り込んでいない変更があるので生成を飛ばしました。先に ./import.sh を実行してください。"
      continue
    fi
    mkdir -p "$(dirname "$target")"
    [ -L "$target" ] && evacuate "$home"
    compose_json "$DOTFILES_DIR/$home" "$name" >"$target.tmp"
    mv "$target.tmp" "$target"
    info "生成しました: ~/$home"
  done < <(manifest)
}

# --- home-manager ---------------------------------------------------------------
home_manager_switch() {
  local flake="$DOTFILES_DIR/.config/home-manager#$USER"
  if command -v home-manager >/dev/null; then
    home-manager switch --impure --flake "$flake"
  else
    nix run home-manager/master -- switch --impure --flake "$flake"
  fi
}
