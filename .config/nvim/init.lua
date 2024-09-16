-- vim.loaderが存在する場合
if vim.loader then
	-- vim.loaderを有効にする
	vim.loader.enable()
end

-- グローバル関数ddを定義
_G.dd = function (...)
	-- util.debugモジュールのdump関数を呼び出す
	require("util.debug").dump(...)
end

-- vim.printをグローバル関数ddに設定
vim.print = _G.dd

-- config.lazyモジュールを読み込む
require("config.lazy")
