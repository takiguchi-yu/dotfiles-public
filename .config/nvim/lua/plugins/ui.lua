return {
	-- メッセージ、コマンドライン、ポップアップメニューの設定
	{
		"folke/noice.nvim",
		opts = function(_, opts)
			-- 特定の通知メッセージをスキップするルートを追加
			table.insert(opts.routes, {
				filter = {
					event = "notify",
					find = "No information available",
				},
				opts = { skip = true },
			})
			local focused = true
			-- フォーカスが得られたときの自動コマンドを作成
			vim.api.nvim_create_autocmd("FocusGained", {
				callback = function()
					focused = true
				end,
			})
			-- フォーカスが失われたときの自動コマンドを作成
			vim.api.nvim_create_autocmd("FocusLost", {
				callback = function()
					focused = false
				end,
			})
			-- フォーカスがないときに通知を送信するルートを追加
			table.insert(opts.routes, 1, {
				filter = {
					cond = function()
						return not focused
					end,
				},
				view = "notify_send",
				opts = { stop = false },
			})

			-- コマンドの設定
			opts.commands = {
				all = {
					-- `:Noice`コマンドで表示されるメッセージ履歴のオプション
					view = "split",
					opts = { enter = true, format = "details" },
					filter = {},
				},
			}

			-- Markdownファイルタイプの自動コマンドを作成
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function(event)
					vim.schedule(function()
						require("noice.text.markdown").keys(event.buf)
					end)
				end,
			})

			-- LSPドキュメントのボーダーを有効にするプリセットを設定
			opts.presets.lsp_doc_border = true
		end,
	},

	-- 通知プラグインの設定
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 5000, -- 通知のタイムアウトを5000ミリ秒に設定
		},
	},

	-- アニメーションプラグインの設定
	{
		"echasnovski/mini.animate",
		event = "VeryLazy", -- 遅延読み込みイベント
		opts = function(_, opts)
			opts.scroll = {
				enable = false, -- スクロールアニメーションを無効にする
			}
		end,
	},

	-- バッファラインプラグインの設定
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy", -- 遅延読み込みイベント
		keys = {
			{ "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "次のタブ" },
			{ "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "前のタブ" },
		},
		opts = {
			options = {
				mode = "tabs", -- タブモードを使用
				-- separator_style = "slant", -- セパレータスタイル（コメントアウト）
				show_buffer_close_icons = false, -- バッファクローズアイコンを非表示
				show_close_icon = false, -- クローズアイコンを非表示
			},
		},
	},

	-- ファイル名表示プラグインの設定
	{
		"b0o/incline.nvim",
		dependencies = { "craftzdog/solarized-osaka.nvim" }, -- 依存プラグイン
		event = "BufReadPre", -- バッファ読み込み前イベント
		priority = 1200, -- 読み込み優先度
		config = function()
			local colors = require("solarized-osaka.colors").setup()
			require("incline").setup({
				highlight = {
					groups = {
						InclineNormal = { guibg = colors.magenta500, guifg = colors.base04 },
						InclineNormalNC = { guifg = colors.violet500, guibg = colors.base03 },
					},
				},
				window = { margin = { vertical = 0, horizontal = 1 } },
				hide = {
					cursorline = true, -- カーソルラインを非表示
				},
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					if vim.bo[props.buf].modified then
						filename = "[+] " .. filename
					end

					local icon, color = require("nvim-web-devicons").get_icon_color(filename)
					return { { icon, guifg = color }, { " " }, { filename } }
				end,
			})
		end,
	},

	-- ステータスラインプラグインの設定
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			local LazyVim = require("lazyvim.util")
			opts.sections.lualine_c[4] = {
				LazyVim.lualine.pretty_path({
					length = 0,
					relative = "cwd",
					modified_hl = "MatchParen",
					directory_hl = "",
					filename_hl = "Bold",
					modified_sign = "",
					readonly_icon = " 󰌾 ",
				}),
			}
		end,
	},

	-- Zenモードプラグインの設定
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode", -- ZenModeコマンドで起動
		opts = {
			plugins = {
				gitsigns = true, -- gitsignsプラグインを有効にする
				tmux = true, -- tmuxプラグインを有効にする
				kitty = { enabled = false, font = "+2" }, -- kittyプラグインの設定
			},
		},
		keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zenモード" } },
	},
}
