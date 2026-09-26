#!/usr/bin/env bash
# 新しい PC で設定をホームに展開する。何度実行しても同じ状態になる。
#
#   ./setup.sh                 ローカル設定が無いものだけ入力を求める
#   ./setup.sh --reconfigure   ローカル設定を入力し直す
#   ./setup.sh --yes           確認をすべて y で進める
#   ./setup.sh --no-skills     外部スキルを入れ直さない
# shellcheck disable=SC2088 # メッセージ中の ~ は表示用
source "$(dirname "$0")/lib/dotfiles.sh"

RECONFIGURE=0
RESTORE_SKILLS=1
for arg in "$@"; do
  case "$arg" in
    --reconfigure) RECONFIGURE=1 ;;
    --yes) ASSUME_YES=1 ;;
    --no-skills) RESTORE_SKILLS=0 ;;
    *) die "不明な引数です: $arg" ;;
  esac
done

# --- 1. 前提 ------------------------------------------------------------------
check_platform() {
  [ "$(uname -s)" = Darwin ] || die "macOS 専用です"
}

# --- 2. nix -------------------------------------------------------------------
# https://github.com/DeterminateSystems/nix-installer
ensure_nix() {
  if command -v nix >/dev/null; then return; fi
  info "nix をインストールします"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
}

# --- 3. ローカル設定 ----------------------------------------------------------
# 入力を求める。既定値があれば Enter でそれを使う。
ask() { # <変数名> <見出し> [既定値]
  local answer
  read -r -p "$2${3:+ [$3]}: " answer </dev/tty
  printf -v "$1" '%s' "${answer:-${3:-}}"
}

ask_secret() { # <変数名> <見出し>
  local answer
  read -r -s -p "$2: " answer </dev/tty
  echo
  printf -v "$1" '%s' "$answer"
}

needs_local() { [ "$RECONFIGURE" = 1 ] || [ ! -e "$LOCAL_DIR/$1" ]; }

# 旧配置（~/.gitconfig-work など）に値があれば、それを既定値にする。
old_git_value() { git config --file "$1" "$2" 2>/dev/null || true; }

write_git_identity() { # <ローカル設定名> <見出し> <旧ファイル> <ssh 鍵を聞くか>
  local name email key file="$LOCAL_DIR/$1"
  needs_local "$1" || return 0
  info "$2 の git ユーザー"
  ask name "  user.name" "$(old_git_value "$3" user.name)"
  ask email "  user.email" "$(old_git_value "$3" user.email)"
  # 上書きするのはユーザーと鍵だけ。手で足した値（secrets.allowed など）は残す。
  git config --file "$file" user.name "$name"
  git config --file "$file" user.email "$email"
  if [ "$4" = yes ]; then
    key="$(old_git_value "$3" core.sshCommand | sed -nE 's/.*-i ([^ ]+).*/\1/p')"
    ask key "  SSH 秘密鍵のパス（空なら ssh の既定）" "$key"
    [ -z "$key" ] || git config --file "$file" core.sshCommand "ssh -i $key -o IdentitiesOnly=yes -F /dev/null"
  fi
}

write_copilot_overlay() {
  local name="copilot-mcp-config.json" base="$DOTFILES_DIR/.copilot/mcp-config.json" server token overlay='{}'
  needs_local "$name" || return 0
  info "GitHub Copilot CLI の MCP サーバーのトークン（空なら設定しない）"
  for server in $(jq -r '.mcpServers | to_entries[] | select(.value.headers.Authorization) | .key' "$base"); do
    ask_secret token "  $server"
    [ -z "$token" ] && continue
    overlay="$(jq --arg s "$server" --arg t "Bearer $token" '.mcpServers[$s].headers.Authorization = $t' <<<"$overlay")"
  done
  (umask 077 && printf '%s\n' "$overlay" >"$LOCAL_DIR/$name")
}

write_claude_overlay() {
  local name="claude-settings.json"
  needs_local "$name" || return 0
  [ -e "$LOCAL_DIR/$name" ] && return 0 # 手で書く内容なので、作り直しでも消さない
  echo '{}' >"$LOCAL_DIR/$name"
  info "$LOCAL_DIR/$name を作りました。業務用の env・許可ルール・フックはここに書きます（README 参照）"
}

write_import_ignore() {
  [ -e "$LOCAL_DIR/import-ignore" ] && return 0
  cat >"$LOCAL_DIR/import-ignore" <<'EOF'
# 取り込みの対象にしないホームのパス（glob）。業務専用ファイルなど、公開リポジトリに入れないものを書く。
# 例: .claude/skills/some-internal-skill
EOF
}

# gitleaks で検出する秘匿値。git のユーザー情報と、追加で入力した語から作る。
write_gitleaks_rules() {
  local words extra
  needs_local gitleaks.toml || return 0
  info "公開リポジトリに入れたくない語（組織名・業務システム名など。カンマ区切り、空でも可）"
  ask extra "  語"
  words="$(
    {
      for f in gitconfig gitconfig-work gitconfig-private; do
        git config --file "$LOCAL_DIR/$f" user.email 2>/dev/null || true
      done
      tr ',' '\n' <<<"$extra"
    } | sed -E 's/^ +| +$//g' | grep -v '^$' | sort -u |
      sed -E 's/[][\\.^$*+?(){}|]/\\&/g' | paste -sd '|' -
  )"
  [ -n "$words" ] || return 0
  cat >"$LOCAL_DIR/gitleaks.toml" <<EOF
# setup.sh が生成する。作り直すには ./setup.sh --reconfigure
[[rules]]
id = "dotfiles-local-secret"
description = "ローカル設定に登録した秘匿値"
regex = '''(?i)($words)'''
EOF
}

write_local_config() {
  mkdir -p "$LOCAL_DIR"
  chmod 700 "$LOCAL_DIR"
  write_git_identity gitconfig "既定（~/git/work・~/git/private 以外）" "$HOME/.gitconfig" no
  write_git_identity gitconfig-work "~/git/work 配下" "$HOME/.gitconfig-work" yes
  write_git_identity gitconfig-private "~/git/private 配下" "$HOME/.gitconfig-private" yes
  write_copilot_overlay
  write_claude_overlay
  write_import_ignore
  write_gitleaks_rules
}

# --- 4. リンク ----------------------------------------------------------------
# home-manager は既存の実体があると止まるので、先に退避する。
# ホームで変更していた内容は、退避先に残る。取り込みたいときは ./import.sh を先に実行する。
# 実体か、リポジトリ以外を指すリンクがあれば退避が要る。
needs_evacuation() { # <ホームのパス> <リポジトリのパス>
  [ -e "$HOME/$1" ] || [ -L "$HOME/$1" ] || return 1
  ! links_to_repo "$1" "$2"
}

evacuate_conflicts() {
  local kind home repo child
  while IFS=$'\t' read -r kind home repo; do
    case "$kind" in
      link)
        if needs_evacuation "$home" "$repo"; then evacuate "$home"; fi
        ;;
      each)
        for child in "$DOTFILES_DIR/$repo"/*; do
          [ -e "$child" ] || continue
          if needs_evacuation "$home/$(basename "$child")" "$repo/$(basename "$child")"; then
            evacuate "$home/$(basename "$child")"
          fi
        done
        ;;
    esac
  done < <(manifest)
}

link_home_manager_dir() {
  local rel=.config/home-manager
  links_to_repo "$rel" "$rel" && return 0
  if [ -e "$HOME/$rel" ] || [ -L "$HOME/$rel" ]; then evacuate "$rel"; fi
  mkdir -p "$HOME/.config"
  ln -s "$DOTFILES_DIR/$rel" "$HOME/$rel"
  info "リンクしました: ~/$rel -> $DOTFILES_DIR/$rel"
}

# --- 5. 外部スキル ------------------------------------------------------------
restore_external_skills() {
  local lock="$DOTFILES_DIR/.agents/.skill-lock.json" source agents skills
  command -v npx >/dev/null || {
    warn "npx が無いので外部スキルの復元を飛ばしました"
    return 0
  }
  agents="$(jq -r '.lastSelectedAgents | join(" ")' "$lock")"
  for source in $(jq -r '[.skills[].source] | unique[]' "$lock"); do
    skills="$(jq -r --arg s "$source" '[.skills | to_entries[] | select(.value.source == $s) | .key] | join(" ")' "$lock")"
    info "外部スキルを入れます: $source ($skills)"
    # shellcheck disable=SC2086
    npx -y skills add "$source" -g -y -a $agents -s $skills || warn "$source の復元に失敗しました"
  done
}

# --- 6. このリポジトリの commit 前検査 ----------------------------------------
install_git_hooks() {
  (cd "$DOTFILES_DIR" && lefthook install)
}

main() {
  check_platform
  ensure_nix
  write_local_config
  link_home_manager_dir
  evacuate_conflicts
  info "home-manager switch"
  home_manager_switch
  compose_all
  install_git_hooks
  if [ "$RESTORE_SKILLS" = 1 ] && confirm "外部スキルを .skill-lock.json から入れ直しますか"; then
    restore_external_skills
  fi
  cat <<'EOF'

セットアップが終わりました。次の手順は手動です。
  - twg / herdr の CLI を入れる（それぞれのスキルも一緒に入る）
  - 業務用の Claude Code 設定を ~/.config/dotfiles/local/claude-settings.json に書き、./setup.sh を再実行する
EOF
}

main
