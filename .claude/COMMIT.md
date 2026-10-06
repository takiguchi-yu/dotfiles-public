## コミットメッセージと PR タイトルはコミットテンプレートの書式で書く

コミット、PR の作成、PR タイトルの変更の前に、`git config --path commit.template` が指すファイル
（既定は `~/.gitcommit_template`）を読み、その書式で書く。Prefix と Emoji は両方付ける。

- **Issue 番号**は、ブランチ名・会話・PR で確認できたときだけ入れる。確認できなければ `#<Issue Number>` ごと省く
- **リポジトリ側に書式の規約**（スキル、CONTRIBUTING、commitlint など）があれば、そちらに従う（@PRACTICE.md の採用優先順位）
