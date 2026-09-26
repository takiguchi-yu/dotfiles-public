# dotfiles

PC を替えても同じ作業環境を再現するための設定。macOS 専用。用語は [CONTEXT.md](CONTEXT.md)、主な判断は [docs/adr/](docs/adr/) にある。

## セットアップ

```sh
git clone git@github.com:takiguchi-yu/dotfiles-public.git ~/git/private/dotfiles-public
cd ~/git/private/dotfiles-public
./setup.sh
```

`setup.sh` がやること（何度実行しても同じ状態になる）。

1. nix が無ければ入れる（[Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)）
2. 秘匿値を聞いて、ローカル設定 `~/.config/dotfiles/local/` を作る（あるものは聞かない。聞き直すには `--reconfigure`）
3. `~/.config/home-manager` をこのリポジトリにリンクする
4. リンク先に実体があれば `~/.local/state/dotfiles/backup/<日時>/` に退避する
5. `home-manager switch --impure` で、`links.txt` の設定をリポジトリへのリンクにする
6. 合成ファイル（`settings.json` など）を、公開分とローカル設定から生成する
7. 自作スキル [claude-skills](https://github.com/takiguchi-yu/claude-skills) を clone し（無ければ、確認のうえ）、その `install.sh` でリンクする
8. このリポジトリの commit 前検査（lefthook + gitleaks）を有効にする
9. 確認のうえ、外部スキルを `.agents/.skill-lock.json` から入れ直す（`--no-skills` で飛ばす）

次は手動で行う。

- twg / herdr の CLI を入れる（それぞれのスキルも一緒に入る）
- 業務用の Claude Code 設定を `~/.config/dotfiles/local/claude-settings.json` に書き、`./setup.sh` を再実行する

リポジトリを別の場所に置くときは、`DOTFILES_DIR`（claude-skills は `CLAUDE_SKILLS_DIR`）にそのパスを入れてから実行する。

## 構成

| パス | 役割 |
| --- | --- |
| `links.txt` | ホームとリポジトリの対応表。何をリンクし、何を合成し、何を取り込まないか |
| `setup.sh` | セットアップ |
| `import.sh` | 取り込み（ホームにしかない設定をリポジトリに移す） |
| `lib/dotfiles.sh` | 上の 2 つが共有する処理（対応表の読み込み、合成） |
| `.config/home-manager/` | home-manager。`links.nix` が `links.txt` からリンクを作る |
| それ以外のドットファイル | ホームと同じパスに置いた設定の本体 |

## ローカル設定

`~/.config/dotfiles/local/` に置く。git では管理しない。

| ファイル | 中身 | 読むもの |
| --- | --- | --- |
| `gitconfig` / `gitconfig-work` / `gitconfig-private` | git のユーザーと SSH 鍵 | `.gitconfig` の include |
| `claude-settings.json` | Claude Code の業務用設定（env、許可ルール、`autoMode`、フック） | 合成して `~/.claude/settings.json` に |
| `copilot-mcp-config.json` | Copilot CLI の MCP トークン | 合成して `~/.copilot/mcp-config.json` に |
| `gitleaks.toml` | commit させない語（自分のアドレス、組織名など） | lefthook の gitleaks |
| `import-ignore` | 取り込まないパス（業務専用ファイルなど） | `import.sh` |

`claude-settings.json` は `~/.claude/settings.json` と同じ形で、足したい部分だけを書く。
オブジェクトは重なり、配列は後ろに足され、それ以外の値は上書きされる。

```json
{
  "env": { "AWS_CA_BUNDLE": "/path/to/ca.pem" },
  "permissions": { "allow": ["Bash(ssh some-bastion:*)"] }
}
```

## 日々の運用

- 設定はホームで普通に編集してよい。リンクなので、そのままリポジトリの差分になる
- 合成ファイル（`~/.claude/settings.json` など）をホームで変えたとき、`~/.claude/hooks` などに新しく作ったとき、ツールがリンクを普通のファイルに置き換えたときは、`./import.sh` で取り込む。差分を 1 件ずつ見せて確認する
- 自作スキルとそのエージェントは claude-skills で管理する（このリポジトリには置かない）
- `links.txt` に行を足したら `home-manager switch --impure`（fish では `hms`）
