-- snacks.nvim のファイラー / ピッカーで隠しファイル・隠しフォルダを既定で表示する
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        -- <leader>e のファイルエクスプローラ
        explorer = {
          hidden = true,
          -- 隠しファイルを表示しても .git ディレクトリはツリーに出さない
          exclude = { ".git" },
        },
        -- <leader>ff などのファイル検索
        files = { hidden = true },
        -- <leader>sg などの grep
        grep = { hidden = true },
      },
    },
  },
}
