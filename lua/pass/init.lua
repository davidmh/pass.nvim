-- [nfnl] fnl/pass/init.fnl
local utils = require("pass.utils")
local actions = require("pass.actions")
local M = {}
M.open = function()
  if not utils["verify-gpg-auth"]() then
    vim.notify("GPG key locked. Attempting to unlock...", vim.log.levels.INFO, {title = "pass.nvim"})
    if not utils["unlock-gpg-key"]() then
      utils.error("Failed to unlock GPG key.")
      return
    else
    end
  else
  end
  local ok_3f, snacks_picker = pcall(require, "snacks.picker")
  if not ok_3f then
    M.error("snacks.nvim is required")
    return
  else
  end
  return snacks_picker.pick({title = "Password Store", items = utils["list-passwords"](), format = "text", layout = {preset = "select"}, win = {input = {keys = {["<c-r>"] = {"rename", mode = {"i", "n"}}, ["<c-d>"] = {"delete", mode = {"i", "n"}}, ["<c-e>"] = {"edit", mode = {"i", "n"}}, ["<c-l>"] = {"log", mode = {"i", "n"}}}}}, confirm = "copy", actions = actions})
end
return M
