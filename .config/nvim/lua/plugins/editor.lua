return {
	{
		enabled = false, -- プラグインを無効化
		"folke/flash.nvim", -- プラグインの名前
		-- @type Flash.Config
		opts = {
			search = {
				forward = true, -- 前方検索を有効化
				multi_window = false, -- 複数ウィンドウでの検索を無効化
				wrap = false, -- 検索の折り返しを無効化
				incremental = true, -- インクリメンタル検索を有効化
			},
		},
	},

	{
		"echasnovski/mini.hipatterns", -- プラグインの名前
		event = "BufReadPre", -- バッファ読み込み前にイベントをトリガー
		opts = {
			highlighters = {
				hsl_color = {
					pattern = "hsl%(%d+,? %d+%%?,? %d+%%?%)", -- HSLカラーのパターン
					group = function(_, match)
						local utils = require("solarized-osaka.hsl") -- HSLユーティリティを読み込む
						--- @type string, string, string
						local nh, ns, nl = match:match("hsl%((%d+),? (%d+)%%?,? (%d+)%%?%)") -- HSL値を抽出
						--- @type number?, number?, number?
						local h, s, l = tonumber(nh), tonumber(ns), tonumber(nl) -- 数値に変換
						--- @type string
						local hex_color = utils.hslToHex(h, s, l) -- HSLをHEXに変換
						local MiniHipatterns = require("mini.hipatterns") -- mini.hipatternsを読み込む
						return MiniHipatterns.compute_hex_color_group(hex_color, "bg") -- HEXカラーグループを計算
					end,
				},
			},
		},
	},

	{
		"dinhhuy258/git.nvim", -- プラグインの名前
		event = "BufReadPre", -- バッファ読み込み前にイベントをトリガー
		opts = {
			keymaps = {
				-- ブレームウィンドウを開く
				blame = "<Leader>gb",
				-- Gitリポジトリ内のファイル/フォルダを開く
				browse = "<Leader>go",
			},
		},
	},

	{
		"telescope.nvim", -- プラグインの名前
		dependencies = {
			{
				"nvim-telescope/telescope-fzf-native.nvim", -- 依存プラグイン
				build = "make", -- ビルドコマンド
			},
			"nvim-telescope/telescope-file-browser.nvim", -- 依存プラグイン
		},
		keys = {
			{
				"<leader>fP",
				function()
					require("telescope.builtin").find_files({
						cwd = require("lazy.core.config").options.root, -- プラグインファイルを検索
					})
				end,
				desc = "Find Plugin File", -- キーマップの説明
			},
			{
				";f",
				function()
					local builtin = require("telescope.builtin")
					builtin.find_files({
						no_ignore = false, -- .gitignoreを無視しない
						hidden = true, -- 隠しファイルを表示
					})
				end,
				desc = "Lists files in your current working directory, respects .gitignore", -- キーマップの説明
			},
			{
				";r",
				function()
					local builtin = require("telescope.builtin")
					builtin.live_grep({
						additional_args = { "--hidden" }, -- 隠しファイルも検索
					})
				end,
				desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore", -- キーマップの説明
			},
			{
				"\\\\",
				function()
					local builtin = require("telescope.builtin")
					builtin.buffers() -- 開いているバッファをリスト表示
				end,
				desc = "Lists open buffers", -- キーマップの説明
			},
			{
				";t",
				function()
					local builtin = require("telescope.builtin")
					builtin.help_tags() -- ヘルプタグをリスト表示
				end,
				desc = "Lists available help tags and opens a new window with the relevant help info on <cr>", -- キーマップの説明
			},
			{
				";;",
				function()
					local builtin = require("telescope.builtin")
					builtin.resume() -- 前回のTelescopeピッカーを再開
				end,
				desc = "Resume the previous telescope picker", -- キーマップの説明
			},
			{
				";e",
				function()
					local builtin = require("telescope.builtin")
					builtin.diagnostics() -- 診断情報をリスト表示
				end,
				desc = "Lists Diagnostics for all open buffers or a specific buffer", -- キーマップの説明
			},
			{
				";s",
				function()
					local builtin = require("telescope.builtin")
					builtin.treesitter() -- Treesitterから関数名や変数をリスト表示
				end,
				desc = "Lists Function names, variables, from Treesitter", -- キーマップの説明
			},
			{
				"sf",
				function()
					local telescope = require("telescope")

					local function telescope_buffer_dir()
						return vim.fn.expand("%:p:h") -- 現在のバッファのディレクトリを取得
					end

					telescope.extensions.file_browser.file_browser({
						path = "%:p:h", -- 現在のバッファのパス
						cwd = telescope_buffer_dir(), -- 現在のバッファのディレクトリ
						respect_gitignore = false, -- .gitignoreを無視しない
						hidden = true, -- 隠しファイルを表示
						grouped = true, -- グループ化を有効化
						previewer = false, -- プレビューを無効化
						initial_mode = "normal", -- 初期モードをノーマルに設定
						layout_config = { height = 40 }, -- レイアウト設定
					})
				end,
				desc = "Open File Browser with the path of the current buffer", -- キーマップの説明
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local fb_actions = require("telescope").extensions.file_browser.actions

			opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
				wrap_results = true, -- 結果を折り返す
				layout_strategy = "horizontal", -- レイアウト戦略を水平に設定
				layout_config = { prompt_position = "top" }, -- プロンプトの位置を上に設定
				sorting_strategy = "ascending", -- ソート順を昇順に設定
				winblend = 0, -- ウィンドウの透明度を設定
				mappings = {
					n = {}, -- ノーマルモードのマッピング
				},
			})
			opts.pickers = {
				diagnostics = {
					theme = "ivy", -- テーマをivyに設定
					initial_mode = "normal", -- 初期モードをノーマルに設定
					layout_config = {
						preview_cutoff = 9999, -- プレビューのカットオフを設定
					},
				},
			}
			opts.extensions = {
				file_browser = {
					theme = "dropdown", -- テーマをドロップダウンに設定
					-- netrwを無効化し、telescope-file-browserを使用
					hijack_netrw = true,
					mappings = {
						-- カスタムインサートモードのマッピング
						["n"] = {
							-- カスタムノーマルモードのマッピング
							["N"] = fb_actions.create, -- 新しいファイル/フォルダを作成
							["h"] = fb_actions.goto_parent_dir, -- 親ディレクトリに移動
							["/"] = function()
								vim.cmd("startinsert") -- インサートモードを開始
							end,
							["<C-u>"] = function(prompt_bufnr)
								for i = 1, 10 do
									actions.move_selection_previous(prompt_bufnr) -- 選択を10行上に移動
								end
							end,
							["<C-d>"] = function(prompt_bufnr)
								for i = 1, 10 do
									actions.move_selection_next(prompt_bufnr) -- 選択を10行下に移動
								end
							end,
							["<PageUp>"] = actions.preview_scrolling_up, -- プレビューを上にスクロール
							["<PageDown>"] = actions.preview_scrolling_down, -- プレビューを下にスクロール
						},
					},
				},
			}
			telescope.setup(opts) -- Telescopeを設定
			require("telescope").load_extension("fzf") -- fzf拡張を読み込む
			require("telescope").load_extension("file_browser") -- file_browser拡張を読み込む
		end,
	},
}
