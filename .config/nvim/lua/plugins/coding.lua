return {
	-- キーバインド一つで注釈を作成し、カーソルを挿入された注釈にジャンプさせる
	{
		"danymat/neogen",
		keys = {
			{
				"<leader>cc",
				function()
					require("neogen").generate({})
				end,
				desc = "Neogen Comment", -- 注釈生成の説明
			},
		},
		opts = { snippet_engine = "luasnip" }, -- スニペットエンジンの設定
	},

	-- インクリメンタルリネーム
	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename", -- コマンドで実行
		config = true, -- デフォルト設定を使用
	},

	-- リファクタリングツール
	{
		"ThePrimeagen/refactoring.nvim",
		keys = {
			{
				"<leader>r",
				function()
					require("refactoring").select_refactor()
				end,
				mode = "v", -- ビジュアルモードで実行
				noremap = true, -- 再マッピングを禁止
				silent = true, -- サイレントモード
				expr = false, -- 式として評価しない
			},
		},
		opts = {}, -- オプションなし
	},

	-- 角括弧で前後に移動
	{
		"echasnovski/mini.bracketed",
		event = "BufReadPost", -- バッファ読み込み後に実行
		config = function()
			local bracketed = require("mini.bracketed")
			bracketed.setup({
				file = { suffix = "" }, -- ファイル移動のサフィックス設定
				window = { suffix = "" }, -- ウィンドウ移動のサフィックス設定
				quickfix = { suffix = "" }, -- クイックフィックス移動のサフィックス設定
				yank = { suffix = "" }, -- ヤンク移動のサフィックス設定
				treesitter = { suffix = "n" }, -- Tree-sitter移動のサフィックス設定
			})
		end,
	},

	-- より良い増減
	{
		"monaqa/dial.nvim",
	-- stylua: ignore
	keys = {
		{ "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" }, -- インクリメント
		{ "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" }, -- デクリメント
	},
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal, -- 10進数の増減
					augend.integer.alias.hex, -- 16進数の増減
					augend.date.alias["%Y/%m/%d"], -- 日付の増減
					augend.constant.alias.bool, -- ブール値の増減
					augend.semver.alias.semver, -- セマンティックバージョンの増減
					augend.constant.new({ elements = { "let", "const" } }), -- 定数の増減
				},
			})
		end,
	},

	-- シンボルアウトライン
	{
		"simrat39/symbols-outline.nvim",
		keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } }, -- シンボルアウトラインのキーバインド
		cmd = "SymbolsOutline", -- コマンドで実行
		opts = {
			position = "right", -- 右側に表示
		},
	},

	-- nvim-cmpの設定
	{
		"nvim-cmp",
		dependencies = { "hrsh7th/cmp-emoji" }, -- 依存関係にcmp-emojiを追加
		opts = function(_, opts)
			table.insert(opts.sources, { name = "emoji" }) -- ソースに絵文字を追加
		end,
	},
}
