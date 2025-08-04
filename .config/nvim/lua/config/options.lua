-- オプションは lazy.nvim の起動前に自動的に読み込まれます
-- 常に設定されるデフォルトのオプション: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- 追加のオプションをここに追加します

vim.g.mapleader = " " -- リーダーキーをスペースに設定

vim.opt.encoding = "utf-8" -- デフォルトのエンコーディングをUTF-8に設定
vim.opt.fileencoding = "utf-8" -- ファイルエンコーディングをUTF-8に設定

vim.opt.number = true -- 行番号を表示

vim.opt.title = true -- ウィンドウのタイトルを設定
vim.opt.autoindent = true -- 自動インデントを有効にする
vim.opt.smartindent = true -- スマートインデントを有効にする
vim.opt.hlsearch = true -- 検索結果をハイライト表示
vim.opt.backup = false -- バックアップファイルを無効にする
vim.opt.showcmd = true -- 画面の最下行にコマンドを表示
vim.opt.cmdheight = 1 -- コマンドラインの高さを1に設定
vim.opt.laststatus = 3 -- 常にステータスラインを表示
vim.opt.expandtab = true -- タブをスペースに変換
vim.opt.scrolloff = 10 -- カーソルの上下に最低限表示する行数を設定
vim.opt.shell = "fish" -- デフォルトのシェルをfishに設定
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" } -- バックアップをスキップするパスを設定
vim.opt.inccommand = "split" -- インクリメンタルサーチの結果を分割ウィンドウに表示
vim.opt.ignorecase = true -- 検索時に大文字小文字を区別しない
vim.opt.smarttab = true -- スマートタブを有効にする
vim.opt.breakindent = true -- 改行時にインデントを保持
vim.opt.shiftwidth = 2 -- シフト幅を2に設定
vim.opt.tabstop = 2 -- タブ幅を2に設定
vim.opt.wrap = false -- 行を折り返さない
vim.opt.backspace = { "start", "eol", "indent" } -- バックスペースの動作を設定
vim.opt.path:append({ "**" }) -- ファイル検索時にサブフォルダも検索対象に含める
vim.opt.wildignore:append({ "*/node_modules/*" }) -- ワイルドカード検索時に無視するパスを設定
vim.opt.splitbelow = true -- 新しいウィンドウを現在のウィンドウの下に開く
vim.opt.splitright = true -- 新しいウィンドウを現在のウィンドウの右に開く
vim.opt.splitkeep = "cursor" -- 分割後もカーソル位置を保持
vim.opt.mouse = "" -- マウスを無効にする

-- アンダーカールを設定（日本語の波線問題のため一時的にコメントアウト）
-- vim.cmd([[let &t_Cs = "\e[4:3m"]])
-- vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- ブロックコメントにアスタリスクを追加
vim.opt.formatoptions:append({ "r" })

-- ファイルタイプを設定
vim.cmd([[au BufNewFile,BufRead *.astro setf astro]])
vim.cmd([[au BufNewFile,BufRead Podfile setf ruby]])

-- Neovim 0.8 以上の場合、コマンドラインの高さを0に設定
if vim.fn.has("nvim-0.8") == 1 then
	vim.opt.cmdheight = 0
end
