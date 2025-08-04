-- lazy.nvimのパスを設定
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
print(lazypath)

-- lazy.nvimが存在しない場合、リポジトリをクローン
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- 最新の安定版リリース
    lazypath,
  })
end

-- ランタイムパスにlazy.nvimを追加
vim.opt.rtp:prepend(lazypath)

-- lazy.nvimの設定を読み込む
require("lazy").setup({
  spec = {
    -- LazyVimとそのプラグインを追加
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = "gruvbox", -- カラースキームを設定
        news = {
          lazyvim = true, -- LazyVimのニュースを表示
          neovim = true, -- Neovimのニュースを表示
        },
      },
    },
    -- 追加のモジュールをインポート
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    --     { import = "lazyvim.plugins.extras.coding.copilot" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.vscode" },
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "lazyvim.plugins.extras.coding.yanky" },
    { import = "lazyvim.plugins.extras.editor.mini-files" },
    { import = "lazyvim.plugins.extras.util.project" },
    { import = "lazyvim.plugins.extras.vscode" },
    { import = "plugins" },
  },
  defaults = {
    -- デフォルトでは、LazyVimプラグインのみが遅延読み込みされる。カスタムプラグインは起動時に読み込まれる。
    -- すべてのカスタムプラグインをデフォルトで遅延読み込みしたい場合は、これを`true`に設定
    lazy = false,
    -- バージョン管理は現時点では無効にすることを推奨。多くのプラグインが古いリリースを持っており、Neovimのインストールを壊す可能性があるため。
    version = false, -- 常に最新のgitコミットを使用
    -- version = "*", -- セマンティックバージョニングをサポートするプラグインの最新安定版をインストール
  },
  dev = {
    path = "~/.ghq/github.com", -- 開発用のパスを設定
  },
  checker = { enabled = true }, -- プラグインの更新を自動的にチェック
  performance = {
    cache = {
      enabled = true, -- キャッシュを有効化
      -- disable_events = {},
    },
    rtp = {
      -- 一部のランタイムパスプラグインを無効化
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  ui = {
    custom_keys = {
      ["<localleader>d"] = function(plugin)
        dd(plugin) -- カスタムキーの設定
      end,
    },
  },
  debug = false, -- デバッグモードを無効化
})
