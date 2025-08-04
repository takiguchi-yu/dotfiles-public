-- see: https://medium.com/@nikmas_dev/vscode-neovim-setup-keyboard-centric-powerful-reliable-clean-and-aesthetic-development-582d34297985

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- remap leader key
keymap("n", "<Space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- yank to system clipboard
keymap({ "n", "v" }, "<leader>y", '"+y', opts) -- <leader>y: システムクリップボードにヤンク

-- paste from system clipboard
keymap({ "n", "v" }, "<leader>p", '"+p', opts) -- <leader>p: システムクリップボードからペースト

-- better indent handling
keymap("v", "<", "<gv", opts) -- ビジュアルモードでインデントを左に移動
keymap("v", ">", ">gv", opts) -- ビジュアルモードでインデントを右に移動

-- move text up and down
keymap("v", "J", ":m .+1<CR>==", opts) -- ビジュアルモードで選択したテキストを1行下に移動
keymap("v", "K", ":m .-2<CR>==", opts) -- ビジュアルモードで選択したテキストを1行上に移動
keymap("x", "J", ":move '>+1<CR>gv-gv", opts) -- ビジュアルラインモードで選択したテキストを1行下に移動
keymap("x", "K", ":move '<-2<CR>gv-gv", opts) -- ビジュアルラインモードで選択したテキストを1行上に移動

-- paste preserves primal yanked piece
keymap("v", "p", '"_dP', opts) -- ビジュアルモードでペーストしてもヤンクした内容を保持

-- removes highlighting after escaping vim search
keymap("n", "<Esc>", "<Esc>:noh<CR>", opts) -- 検索ハイライトを解除

-- call vscode commands from neovim

-- general keymaps
keymap({ "n", "v" }, "<leader>t", "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>") -- <leader>t: ターミナルのトグル
keymap({ "n", "v" }, "<leader>b", "<cmd>lua require('vscode').action('editor.debug.action.toggleBreakpoint')<CR>") -- <leader>b: ブレークポイントのトグル
keymap({ "n", "v" }, "<leader>d", "<cmd>lua require('vscode').action('editor.action.showHover')<CR>") -- <leader>d: ホバー情報の表示
keymap({ "n", "v" }, "<leader>a", "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>") -- <leader>a: クイックフィックスの表示
keymap({ "n", "v" }, "<leader>sp", "<cmd>lua require('vscode').action('workbench.actions.view.problems')<CR>") -- <leader>sp: 問題ビューの表示
keymap({ "n", "v" }, "<leader>cn", "<cmd>lua require('vscode').action('notifications.clearAll')<CR>") -- <leader>cn: 通知のクリア
keymap({ "n", "v" }, "<leader>ff", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>") -- <leader>ff: クイックオープン
keymap({ "n", "v" }, "<leader>cp", "<cmd>lua require('vscode').action('workbench.action.showCommands')<CR>") -- <leader>cp: コマンドパレットの表示
keymap({ "n", "v" }, "<leader>pr", "<cmd>lua require('vscode').action('code-runner.run')<CR>") -- <leader>pr: コードの実行
keymap({ "n", "v" }, "<leader>fd", "<cmd>lua require('vscode').action('editor.action.formatDocument')<CR>") -- <leader>fd: ドキュメントのフォーマット
keymap({ "n", "v" }, "<leader>i", "<cmd>lua require('vscode').action('editor.action.goToImplementation')<CR>") -- <leader>i: 実装クラスにジャンプ
