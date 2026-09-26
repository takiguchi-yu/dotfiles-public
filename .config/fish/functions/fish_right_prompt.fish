# メイン関数
function fish_right_prompt
    render_git_identity
end

# 現在の Github アカウントを表示
function render_git_identity
    # Gitリポジトリ内でなければ何もしない
    if not type -q git; or not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        return
    end

    set -l current_email (git config user.email)

    # アドレスは秘匿値なので、ローカル設定の git ユーザーと照合する。
    # user.email のほかに、dotfiles.email で追加のアドレスを書ける。
    set -l local_dir ~/.config/dotfiles/local
    set -l work_emails
    for f in $local_dir/gitconfig $local_dir/gitconfig-work
        test -f $f; or continue
        set -a work_emails (git config --file $f user.email) (git config --file $f --get-all dotfiles.email)
    end
    set -l private_emails
    if test -f $local_dir/gitconfig-private
        set private_emails (git config --file $local_dir/gitconfig-private user.email) (git config --file $local_dir/gitconfig-private --get-all dotfiles.email)
    end

    if contains -- $current_email $work_emails
        set_color 00d7ff # Cyan
        echo "💼 Work "
    else if contains -- $current_email $private_emails
        set_color ffaf00 # Yellow
        echo "🏠 Private "
    else
        set_color red
        echo "❓ $current_email "
    end

    set_color normal
end
