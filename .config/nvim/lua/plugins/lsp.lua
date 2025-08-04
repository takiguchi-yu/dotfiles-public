return {
	-- ツールの設定
	{
		"mason-org/mason.nvim", -- mason.nvimプラグインの指定
		opts = function(_, opts)
			-- ensure_installedリストにツールを追加
			vim.list_extend(opts.ensure_installed, {
				"stylua", -- Luaのコードフォーマッタ
				"selene", -- Luaの静的解析ツール
				"luacheck", -- LuaのLintツール
				"shellcheck", -- シェルスクリプトのLintツール
				"shfmt", -- シェルスクリプトのフォーマッタ
				"tailwindcss-language-server", -- Tailwind CSSの言語サーバー
				"typescript-language-server", -- TypeScriptの言語サーバー
				"css-lsp", -- CSSの言語サーバー
			})
		end,
	},
	-- LSPサーバーの設定
	{
		"neovim/nvim-lspconfig", -- nvim-lspconfigプラグインの指定
		opts = {
			inlay_hints = { enabled = false }, -- インレイヒントを無効化
			servers = {
				cssls = {}, -- CSS LSPの設定
				tailwindcss = {
					-- Tailwind CSSのルートディレクトリの設定
					root_dir = function(...)
						return require("lspconfig.util").root_pattern(".git")(...)
					end,
				},
				tsserver = {
					-- TypeScriptサーバーのルートディレクトリの設定
					root_dir = function(...)
						return require("lspconfig.util").root_pattern(".git")(...)
					end,
					single_file_support = false, -- 単一ファイルのサポートを無効化
					settings = {
						typescript = {
							-- TypeScriptのインレイヒントの設定
							inlayHints = {
								includeInlayParameterNameHints = "literal",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = false,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
						javascript = {
							-- JavaScriptのインレイヒントの設定
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				},
				html = {}, -- HTML LSPの設定
				yamlls = {
					-- YAML LSPの設定
					settings = {
						yaml = {
							keyOrdering = false, -- キーの順序を無効化
						},
					},
				},
				lua_ls = {
					-- Lua LSPの設定
					single_file_support = true, -- 単一ファイルのサポートを有効化
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false, -- サードパーティのチェックを無効化
							},
							completion = {
								workspaceWord = true, -- ワークスペース内の単語補完を有効化
								callSnippet = "Both", -- スニペットの呼び出しを両方に設定
							},
							misc = {
								parameters = {
									-- "--log-level=trace", -- ログレベルをトレースに設定（コメントアウト）
								},
							},
							hint = {
								enable = true, -- ヒントを有効化
								setType = false, -- 型の設定を無効化
								paramType = true, -- パラメータの型ヒントを有効化
								paramName = "Disable", -- パラメータ名のヒントを無効化
								semicolon = "Disable", -- セミコロンのヒントを無効化
								arrayIndex = "Disable", -- 配列インデックスのヒントを無効化
							},
							doc = {
								privateName = { "^_" }, -- プライベート名の設定
							},
							type = {
								castNumberToInteger = true, -- 数値を整数にキャストする設定
							},
							diagnostics = {
								disable = { "incomplete-signature-doc", "trailing-space" }, -- 無効化する診断の設定
								groupSeverity = {
									strong = "Warning", -- 強い警告の設定
									strict = "Warning", -- 厳しい警告の設定
								},
								groupFileStatus = {
									["ambiguity"] = "Opened", -- 曖昧さのステータス設定
									["await"] = "Opened", -- awaitのステータス設定
									["codestyle"] = "None", -- コードスタイルのステータス設定
									["duplicate"] = "Opened", -- 重複のステータス設定
									["global"] = "Opened", -- グローバルのステータス設定
									["luadoc"] = "Opened", -- Luaドキュメントのステータス設定
									["redefined"] = "Opened", -- 再定義のステータス設定
									["strict"] = "Opened", -- 厳格のステータス設定
									["strong"] = "Opened", -- 強いのステータス設定
									["type-check"] = "Opened", -- 型チェックのステータス設定
									["unbalanced"] = "Opened", -- 不均衡のステータス設定
									["unused"] = "Opened", -- 未使用のステータス設定
								},
								unusedLocalExclude = { "_*" }, -- 未使用のローカル変数の除外設定
							},
							format = {
								enable = false, -- フォーマットを無効化
								defaultConfig = {
									indent_style = "space", -- インデントスタイルをスペースに設定
									indent_size = "2", -- インデントサイズを2に設定
									continuation_indent_size = "2", -- 継続インデントサイズを2に設定
								},
							},
						},
					},
				},
			},
			setup = {}, -- LSPサーバーのセットアップ設定
		},
	},
	{
		"neovim/nvim-lspconfig", -- nvim-lspconfigプラグインの指定
		opts = function()
			local keys = require("lazyvim.plugins.lsp.keymaps").get() -- キーマップの取得
			vim.list_extend(keys, {
				{
					"gd", -- キーバインドの設定
					function()
						-- ウィンドウを再利用しない設定
						require("telescope.builtin").lsp_definitions({ reuse_win = false })
					end,
					desc = "Goto Definition", -- キーバインドの説明
					has = "definition", -- 定義がある場合に有効化
				},
			})
		end,
	},
}
