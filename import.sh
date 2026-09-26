#!/usr/bin/env bash
# 取り込み: ホームにしかない設定をリポジトリに移す。
#
#   - リポジトリを指していない（リンクが普通のファイルに置き換わった）設定
#   - each で管理するディレクトリに、ホームで新しく作った項目
#   - 合成ファイルへのホームでの変更（ローカル設定の分は取り除いて戻す）
#
# 1 件ずつ差分を見せて確認する。--yes ですべて y。終わったら home-manager でリンクを張り直す。
# shellcheck disable=SC2088 # メッセージ中の ~ は表示用
source "$(dirname "$0")/lib/dotfiles.sh"

for arg in "$@"; do
  case "$arg" in
    --yes) ASSUME_YES=1 ;;
    *) die "不明な引数です: $arg" ;;
  esac
done

CHANGED=0

show_diff() { # <リポジトリのパス> <ホームのパス>
  if [ -e "$1" ]; then
    diff -ru "$1" "$2" || true
  else
    echo "（新規）$2"
  fi
}

# ホームの実体をリポジトリに写し、ホーム側は退避する（次の switch でリンクになる）。
import_path() { # <ホームのパス> <リポジトリのパス>
  local home="$HOME/$1" repo="$DOTFILES_DIR/$2"
  if [ -e "$repo" ] && diff -rq "$repo" "$home" >/dev/null; then
    evacuate "$1"
    CHANGED=1
    return
  fi
  show_diff "$repo" "$home"
  confirm "~/$1 を取り込みますか" || return 0
  rm -rf "$repo"
  mkdir -p "$(dirname "$repo")"
  cp -R "$home" "$repo"
  evacuate "$1"
  CHANGED=1
}

import_links() {
  local kind home repo child rel
  while IFS=$'\t' read -r kind home repo; do
    case "$kind" in
      link)
        [ -e "$HOME/$home" ] && [ ! -L "$HOME/$home" ] || continue
        is_ignored "$home" && continue
        import_path "$home" "$repo"
        ;;
      each)
        [ -d "$HOME/$home" ] || continue
        for child in "$HOME/$home"/* "$HOME/$home"/.[!.]*; do
          [ -e "$child" ] && [ ! -L "$child" ] || continue
          rel="$home/$(basename "$child")"
          is_ignored "$rel" && continue
          import_path "$rel" "$repo/$(basename "$child")"
        done
        ;;
    esac
  done < <(manifest)
}

import_composed() {
  local kind home name repo
  while IFS=$'\t' read -r kind home name; do
    [ "$kind" = compose ] || continue
    repo="$DOTFILES_DIR/$home"
    has_unimported_changes "$home" "$name" || continue
    diff -u <(jq . "$repo") <(decompose_json "$HOME/$home" "$name" "$repo") || true
    confirm "~/$home の変更を取り込みますか（ローカル設定の分は除いています）" || continue
    decompose_json "$HOME/$home" "$name" "$repo" >"$repo.tmp"
    mv "$repo.tmp" "$repo"
  done < <(manifest)
}

main() {
  import_links
  import_composed
  if [ "$CHANGED" = 1 ]; then
    info "home-manager switch でリンクを張り直します"
    home_manager_switch
  fi
  info "取り込みが終わりました。git diff で確認して commit してください"
}

main
