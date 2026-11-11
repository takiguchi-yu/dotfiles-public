# Homebrew で入れるもの。setup.sh が brew bundle で入れる。
# Nix（home-manager）で入るものはここに書かない（home.nix の home.packages を見る）。
# 会社の MDM や App Store が配るアプリ（Slack、Google Drive、Office など）も書かない。

tap "penso/tap"

# --- CLI ---------------------------------------------------------------------
brew "asdf"            # 言語ごとのバージョン管理（~/.tool-versions）
brew "ffmpeg"          # 動画・音声の変換
brew "git-secrets"     # AWS の鍵を commit させない（パターンは ~/.gitconfig）
brew "imagemagick"     # 画像の変換。Claude の pdf・pptx スキルが使う
brew "mcp-publisher"   # MCP Registry への公開
brew "neovim"
brew "poppler"         # pdftotext・pdftoppm。Claude の pdf・pptx スキルが使う
brew "rtk"             # Claude Code の Bash 出力を縮める（RTK.md）

# --- 端末・フォント ----------------------------------------------------------
cask "ghostty"
cask "penso/tap/herdr-gpui", trusted: true
cask "iterm2"
cask "font-moralerspace"            # ghostty・herdr の本文フォント
cask "font-symbols-only-nerd-font"  # herdr のアイコン

# --- 開発ツール --------------------------------------------------------------
cask "visual-studio-code"
cask "claude"
cask "dbeaver-community"
cask "another-redis-desktop-manager"
cask "postman"
cask "cyberduck"
cask "session-manager-plugin"  # aws ssm start-session に要る

# --- 入力・操作 --------------------------------------------------------------
cask "karabiner-elements"
cask "bettertouchtool"
cask "raycast"
cask "scroll-reverser"
cask "amical"  # 音声入力

# --- その他 ------------------------------------------------------------------
cask "google-chrome"
cask "dropbox"
cask "figma"
cask "min"  # 軽量ブラウザ
