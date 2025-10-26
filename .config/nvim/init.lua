if vim.g.vscode then
  require("user.vscode_keymaps")
  -- return
end


if vim.loader then
  vim.loader.enable()
end

require("config.lazy")
