-- キーマップは VeryLazy イベントで自動的にロードされます
-- 常に設定されるデフォルトのキーマップ: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- 追加のキーマップをここに追加します

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- レジスタに影響を与えずに操作を行う
keymap.set("n", "x", '"_x')
keymap.set("n", "<Leader>p", '"0p')
keymap.set("n", "<Leader>P", '"0P')
keymap.set("v", "<Leader>p", '"0p')
keymap.set("n", "<Leader>c", '"_c')
keymap.set("n", "<Leader>C", '"_C')
keymap.set("v", "<Leader>c", '"_c')
keymap.set("v", "<Leader>C", '"_C')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')

-- インクリメント/デクリメント
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- 単語を後方に削除
-- keymap.set("n", "dw", 'vb"_d')

-- 全選択
keymap.set("n", "<C-a>", "gg<S-v>G")

-- ルート権限で保存 (現在は動作しない)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

-- 継続を無効にする
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)

-- ジャンプリスト
keymap.set("n", "<C-m>", "<C-i>", opts)

-- 新しいタブ
keymap.set("n", "te", ":tabedit")
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
-- ウィンドウを分割
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)
-- ウィンドウを移動
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- ウィンドウのサイズを変更
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- 診断
keymap.set("n", "<C-j>", function()
	vim.diagnostic.goto_next()
end, opts)
