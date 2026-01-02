-- [nfnl] plugin/pass.fnl
local function open_picker()
  local pass = require("pass")
  return pass.open()
end
return vim.api.nvim_create_user_command("Pass", open_picker, {nargs = 0})
