-- selene: allow(global_usage)

local M = {}

-- 現在の呼び出し元のファイル名と行番号を取得する関数
function M.get_loc()
  local me = debug.getinfo(1, "S") -- 現在の関数のデバッグ情報を取得
  local level = 2
  local info = debug.getinfo(level, "S") -- 呼び出し元のデバッグ情報を取得
  while info and (info.source == me.source or info.source == "@" .. vim.env.MYVIMRC or info.what ~= "Lua") do
    level = level + 1
    info = debug.getinfo(level, "S") -- 呼び出し元が特定の条件を満たす限り、さらに上の呼び出し元を取得
  end
  info = info or me -- 条件を満たす呼び出し元がなければ現在の関数の情報を使用
  local source = info.source:sub(2) -- ファイルパスの先頭の '@' を削除
  source = vim.loop.fs_realpath(source) or source -- ファイルパスを絶対パスに変換
  return source .. ":" .. info.linedefined -- ファイルパスと行番号を返す
end

-- 任意の値をデバッグ出力する関数
---@param value any
---@param opts? {loc:string}
function M._dump(value, opts)
  opts = opts or {} -- オプションが指定されていない場合は空のテーブルを使用
  opts.loc = opts.loc or M.get_loc() -- オプションに loc が指定されていない場合は現在の呼び出し元の位置を取得
  if vim.in_fast_event() then
    return vim.schedule(function()
      M._dump(value, opts) -- 高速イベント内で呼び出された場合はスケジュールして後で実行
    end)
  end
  opts.loc = vim.fn.fnamemodify(opts.loc, ":~:.") -- ファイルパスを短縮表示に変換
  local msg = vim.inspect(value) -- 値を文字列に変換
  vim.notify(msg, vim.log.levels.INFO, {
    title = "Debug: " .. opts.loc, -- デバッグメッセージのタイトルに位置情報を追加
    on_open = function(win)
      vim.wo[win].conceallevel = 3 -- ウィンドウの設定を変更
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      if not pcall(vim.treesitter.start, buf, "lua") then
        vim.bo[buf].filetype = "lua" -- Treesitter が失敗した場合はファイルタイプを Lua に設定
      end
    end,
  })
end

-- 任意の値をデバッグ出力するためのラッパー関数
function M.dump(...)
  local value = { ... } -- 可変長引数をテーブルに格納
  if vim.tbl_isempty(value) then
    value = {} -- 引数が空の場合は空のテーブルを使用
  else
    value = vim.tbl_islist(value) and vim.tbl_count(value) <= 1 and value[1] or value -- 引数が1つの場合はその値を使用
  end
  M._dump(value) -- デバッグ出力関数を呼び出し
end

-- 拡張マークのリークを検出する関数
function M.extmark_leaks()
  local nsn = vim.api.nvim_get_namespaces() -- 全ての名前空間を取得

  local counts = {}

  for name, ns in pairs(nsn) do
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local count = #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) -- バッファ内の拡張マークの数を取得
      if count > 0 then
        counts[#counts + 1] = {
          name = name,
          buf = buf,
          count = count,
          ft = vim.bo[buf].ft, -- バッファのファイルタイプを取得
        }
      end
    end
  end
  table.sort(counts, function(a, b)
    return a.count > b.count -- 拡張マークの数でソート
  end)
  dd(counts) -- 結果をデバッグ出力
end

-- 任意の値のメモリサイズを推定する関数
function estimateSize(value, visited)
  if value == nil then
    return 0
  end
  local bytes = 0

  -- 訪問済みのテーブルを初期化
  --- @type table<any, true>
  visited = visited or {}

  -- 無限再帰を避けるために既に訪問済みの値を処理
  if visited[value] then
    return 0
  else
    visited[value] = true
  end

  if type(value) == "boolean" or value == nil then
    bytes = 4 -- ブール値または nil のサイズ
  elseif type(value) == "number" then
    bytes = 8 -- 数値のサイズ
  elseif type(value) == "string" then
    bytes = string.len(value) + 24 -- 文字列のサイズ
  elseif type(value) == "function" then
    bytes = 32 -- 関数の基本サイズ
    -- アップバリューのサイズを追加
    local i = 1
    while true do
      local name, val = debug.getupvalue(value, i)
      if not name then
        break
      end
      bytes = bytes + estimateSize(val, visited)
      i = i + 1
    end
  elseif type(value) == "table" then
    bytes = 40 -- テーブルエントリの基本サイズ
    for k, v in pairs(value) do
      bytes = bytes + estimateSize(k, visited) + estimateSize(v, visited) -- キーと値のサイズを追加
    end
    local mt = debug.getmetatable(value)
    if mt then
      bytes = bytes + estimateSize(mt, visited) -- メタテーブルのサイズを追加
    end
  end
  return bytes
end

-- モジュールのメモリリークを検出する関数
function M.module_leaks(filter)
  local sizes = {}
  for modname, mod in pairs(package.loaded) do
    if not filter or modname:match(filter) then
      local root = modname:match("^([^%.]+)%..*$") or modname
      -- root = modname
      sizes[root] = sizes[root] or { mod = root, size = 0 }
      sizes[root].size = sizes[root].size + estimateSize(mod) / 1024 / 1024 -- モジュールのサイズをメガバイト単位で計算
    end
  end
  sizes = vim.tbl_values(sizes)
  table.sort(sizes, function(a, b)
    return a.size > b.size -- サイズでソート
  end)
  dd(sizes) -- 結果をデバッグ出力
end

-- 関数のアップバリューを取得する関数
function M.get_upvalue(func, name)
  local i = 1
  while true do
    local n, v = debug.getupvalue(func, i)
    if not n then
      break
    end
    if n == name then
      return v -- 指定された名前のアップバリューを返す
    end
    i = i + 1
  end
end

return M
