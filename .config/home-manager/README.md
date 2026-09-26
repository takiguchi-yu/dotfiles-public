home manager configuration for my personal use.

ユーザー名・ホーム・リポジトリの場所を実行環境から取るので、`--impure` を付ける。

```sh
home-manager switch --impure
```

リンクの対象はリポジトリ直下の `links.txt` に書く（`links.nix` が読む）。
