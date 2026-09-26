## RTK - Rust Token Killer

Bash コマンドは hook が自動で `rtk` 経由に書き換える（出力を最大 90% 削減）。自分で `rtk` を付ける必要はない。
出力が `[N more lines]` で切られて必要な行が読めないときは、`rtk proxy <cmd>` で生出力を取り直す。
`git` だけは書き換え対象外（`~/Library/Application Support/rtk/config.toml` の `exclude_commands`）。worktree 隔離セッションのガードが `rtk git …` を拒否するため。
