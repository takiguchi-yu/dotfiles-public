## AWS / IaC は参照系のみ、更新は承認を得てから

- **AWS CLI は参照系のみ実行してよい**（`describe-`, `list-`, `get-` など）。リソースを作成・変更・削除する操作は実行しない。例: `create-`, `update-`, `put-`, `modify-`, `attach-`, `detach-`, `delete-`, `terminate-`, `remove-`, `stop-`, `reboot-`, `disable-`, および `s3 rm` / `s3 rb` / `s3 mv` / `s3 sync`。**この列挙は例示であり、列挙外なら安全という意味ではない。** 参照系だと確信できないものは実行せず確認する。
- **Terraform / IaC は `plan` `validate` `fmt` `show` のみ実行してよい。** `apply` `destroy` `import` `state rm` `taint` は実行しない。
- 上の 2 つで「実行しない」とした操作は、ユーザーが実行を許可・承認した場合のみ実行してよい。破壊度の高いものは `~/.claude/settings.json` の `permissions.ask` にも登録済みで、実行前に確認プロンプトが出る（[プロンプト規定自体に強制力は無い](https://code.claude.com/docs/en/permissions)ため、二重の防御にしている）。ask ルールはコマンドの書き方によってはすり抜けるので、これに頼り切らず上の規定も守ること。
- CA 証明書（`AWS_CA_BUNDLE`）とページャー無効化（`AWS_PAGER=""`）は `~/.claude/settings.json` の `env` で設定済みなので、コマンドごとに付与する必要はない。SSL エラーやページャー待ちが起きた場合のみ、環境変数が効いているかを疑う。
