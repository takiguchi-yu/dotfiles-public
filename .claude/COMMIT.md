## コミットメッセージはコミットテンプレートの書式で書く

コミットする前に `git config --path commit.template` が指すファイル（既定は `~/.gitcommit_template`）を読み、
その書式と Prefix・Emoji の一覧に従って件名を書く。

- **Issue 番号**は、ブランチ名・会話・PR で確認できたときだけ入れる。確認できなければ `#<Issue Number>` ごと省く
