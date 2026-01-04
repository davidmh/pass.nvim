-- [nfnl] plugin/pass.fnl
local pass = require("pass")
local utils = require("pass.utils")
local subcmds = {"copy", "edit", "insert", "delete", "rename", "log"}
local function complete(arg_lead, cmd_line, cursor_pos)
  local args = vim.split(cmd_line, " ")
  local n = #args
  if (n == 2) then
    local tbl_26_ = {}
    local i_27_ = 0
    for _, v in ipairs(subcmds) do
      local val_28_
      if vim.startswith(v, arg_lead) then
        val_28_ = v
      else
        val_28_ = nil
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  else
    local cmd = args[2]
    if ((cmd ~= "log") and vim.list_contains(subcmds, cmd)) then
      local passwords = utils["list-passwords"]()
      local tbl_26_ = {}
      local i_27_ = 0
      for _, v in ipairs(passwords) do
        local val_28_
        if vim.startswith(v.text, arg_lead) then
          val_28_ = v.text
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    else
      return nil
    end
  end
end
local function tail(arr)
  local elems = vim.tbl_extend("keep", arr, {})
  table.remove(elems, 1)
  return elems
end
local function command_handler(_7_)
  local args = _7_.args
  local fargs = _7_.fargs
  local cmd = fargs[1]
  local path = table.concat(tail(fargs), " ")
  if not utils["verify-gpg-auth"]() then
    utils.debug("GPG key locked. Attempting to unlock...")
    if not utils["unlock-gpg-key"]() then
      utils.error("Failed to unlock GPG key.")
      return
    else
    end
  else
  end
  if (cmd == "copy") then
    return pass.copy({text = path})
  elseif (cmd == "edit") then
    return pass.edit(nil, {text = path})
  elseif (cmd == "insert") then
    if (path == "") then
      return pass.insert({finder = {filter = {pattern = path}}})
    else
      return pass.edit(nil, {text = path})
    end
  elseif (cmd == "delete") then
    return pass.delete(nil, {text = path})
  elseif (cmd == "rename") then
    return pass.rename(nil, {text = path})
  elseif (cmd == "log") then
    return pass.log()
  else
    local _ = cmd
    return pass.open(args)
  end
end
return vim.api.nvim_create_user_command("Pass", command_handler, {nargs = "*", complete = complete})
