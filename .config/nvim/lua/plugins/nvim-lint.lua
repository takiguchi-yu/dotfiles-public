-- markdownlint に、cwd に依らずグローバル設定を読ませる
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      -- nvim-lint は stdin ("-") で渡すため設定探索が cwd 基準になる。
      -- --config を明示して、どこでファイルを開いても同じルールが効くようにする。
      ["markdownlint-cli2"] = {
        args = { "--config", vim.fn.expand("~/.markdownlint-cli2.jsonc"), "-" },
      },
    },
  },
}
