# メイン関数（右側に何か表示するシステム既定のフック）
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

    switch $current_email
        # 仕事用
        case "work@company.co.jp" "work@company.com"
            set_color 00d7ff # Cyan
            echo "💼 Work "

        # プライベート用
        case "private@gmail.com"
            set_color ffaf00 # Yellow
            echo "🏠 Private "

        # その他
        case '*'
            set_color red
            echo "❓ $current_email "
    end

    set_color normal
end
