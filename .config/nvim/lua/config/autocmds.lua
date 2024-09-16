-- Autocmd は VeryLazy イベントで自動的にロードされます
-- 常に設定されるデフォルトの autocmd: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- 追加の autocmd をここに追加します

-- 挿入モードを終了するときにペーストモードをオフにする
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*", -- すべてのファイルタイプに対して適用
	command = "set nopaste", -- ペーストモードをオフにするコマンド
})

-- 特定のファイル形式でコンシールを無効にする
-- LazyVimのデフォルトのconceallevelは3
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc", "markdown" }, -- 対象となるファイル形式
	callback = function()
		vim.opt.conceallevel = 0 -- conceallevelを0に設定してコンシールを無効にする
	end,
})
