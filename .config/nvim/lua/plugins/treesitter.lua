return {
	-- nvim-treesitter/playgroundプラグインを追加し、TSPlaygroundToggleコマンドで起動
	{ "nvim-treesitter/playground", cmd = "TSPlaygroundToggle" },

	{
		-- nvim-treesitter/nvim-treesitterプラグインを追加
		"nvim-treesitter/nvim-treesitter",
		opts = {
			-- インストールする言語のリストを指定
			ensure_installed = {
				"astro",
				"cmake",
				"cpp",
				"css",
				"fish",
				"gitignore",
				"go",
				"graphql",
				"http",
				"java",
				"php",
				"rust",
				"scss",
				"sql",
				"svelte",
			},

			-- matchup機能の設定（コメントアウトされている）
			-- matchup = {
			-- 	enable = true,
			-- },

			-- query_linterの設定
			query_linter = {
				enable = true, -- 有効化
				use_virtual_text = true, -- 仮想テキストを使用
				lint_events = { "BufWrite", "CursorHold" }, -- リントイベントを指定
			},

			-- playgroundの設定
			playground = {
				enable = true, -- 有効化
				disable = {}, -- 無効化する言語のリスト（空）
				updatetime = 25, -- ハイライト更新のデバウンス時間
				persist_queries = true, -- クエリをセッション間で保持
				keybindings = { -- キーバインドの設定
					toggle_query_editor = "o",
					toggle_hl_groups = "i",
					toggle_injected_languages = "t",
					toggle_anonymous_nodes = "a",
					toggle_language_display = "I",
					focus_language = "f",
					unfocus_language = "F",
					update = "R",
					goto_node = "<cr>",
					show_help = "?",
				},
			},
		},
		-- プラグインの設定を行う関数
		config = function(_, opts)
			-- nvim-treesitterの設定を適用
			require("nvim-treesitter.configs").setup(opts)

			-- MDXファイルタイプの追加
			vim.filetype.add({
				extension = {
					mdx = "mdx", -- 拡張子mdxをmdxファイルタイプに関連付け
				},
			})
			-- MDXファイルに対してmarkdown言語を登録
			vim.treesitter.language.register("markdown", "mdx")
		end,
	},
}
