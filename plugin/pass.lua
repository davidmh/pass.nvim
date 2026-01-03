-- [nfnl] plugin/pass.fnl
local function open_picker(_1_)
  local args = _1_.args
  local pass = require("pass")
  return pass.open(args)
end
return vim.api.nvim_create_user_command("Pass", open_picker, {nargs = "?"})
