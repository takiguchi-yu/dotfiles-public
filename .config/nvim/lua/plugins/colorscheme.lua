return {
	{
		-- プラグイン "craftzdog/solarized-osaka.nvim" を指定
		"craftzdog/solarized-osaka.nvim",
		-- プラグインを遅延読み込みする設定
		lazy = true,
		-- プラグインの読み込み優先度を設定
		priority = 1000,
		-- プラグインのオプションを設定する関数
		opts = function()
			return {
				-- 透明背景を有効にするオプション
				transparent = true,
			}
		end,
	},
}
