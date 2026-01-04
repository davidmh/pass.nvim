-- [nfnl] fnl/pass/init.fnl
local _local_1_ = require("pass.module")
local define = _local_1_.define
local utils = require("pass.utils")
local M = define("pass", {})
local function update_password_on_save(_2_)
  local buf = _2_.buf
  local old_content = _2_["old-content"]
  local path = _2_.path
  local picker = _2_.picker
  local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local new_content = table.concat(new_lines, "\n")
  if (vim.trim(new_content) == vim.trim(old_content)) then
    utils.debug("The password didn't change")
    return
  else
  end
  if (new_content == "") then
    local function _4_()
      return M.delete(picker, {text = path})
    end
    vim.schedule(_4_)
    return
  else
  end
  local ok_3f = pcall(utils["save-content"], path, new_content)
  if ok_3f then
    utils.info(("Password saved: " .. path))
    vim.api.nvim_set_option_value("modified", false, {scope = "local", buf = buf})
  else
    utils.error(("Failed to save password: " .. path))
  end
  return nil
end
M.edit = function(picker, entry)
  local path = ((entry and entry.text) or picker.finder.filter.pattern)
  picker:close()
  if (vim.trim(path) == "") then
    return
  else
  end
  local ok_3f, result = pcall(utils.show, path)
  local content
  if ok_3f then
    content = result
  else
    content = ""
  end
  local label
  if ok_3f then
    label = "Edit"
  else
    label = "Insert"
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, ("pass://" .. path))
  vim.api.nvim_set_option_value("buftype", "acwrite", {scope = "local", buf = buf})
  vim.api.nvim_set_option_value("filetype", "pass", {scope = "local", buf = buf})
  vim.api.nvim_set_option_value("bufhidden", "wipe", {scope = "local", buf = buf})
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  local width = math.min(80, (vim.o.columns - 4))
  local height = math.min(20, (vim.o.lines - 4))
  local row = math.floor(((vim.o.lines - height) / 2))
  local col = math.floor(((vim.o.columns - width) / 2))
  local win_config = {relative = "editor", width = width, height = height, row = row, col = col, style = "minimal", border = "rounded", title = (" " .. label .. ": " .. path .. " "), title_pos = "center"}
  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.api.nvim_set_option_value("winblend", 0, {win = win})
  utils["disable-backup-options"]()
  local function _10_()
    return update_password_on_save({buf = buf, path = path, picker = picker, ["old-content"] = content})
  end
  return vim.api.nvim_create_autocmd("BufWriteCmd", {buffer = buf, callback = _10_})
end
M.rename = function(picker, entry)
  if not entry then
    return
  else
  end
  local old_path = entry.text
  local function on_rename(new_path)
    if (not new_path or (new_path == old_path)) then
      return
    else
    end
    local ok_3f = pcall(utils.mv, old_path, new_path)
    if ok_3f then
      utils.info(("Renamed " .. old_path .. " to " .. new_path))
    else
      utils.error(("Failed to rename " .. old_path))
    end
    local pattern = picker.finder.filter.pattern
    picker:close()
    return M.open(pattern)
  end
  return vim.ui.input({prompt = ("Rename " .. old_path), default = old_path}, on_rename)
end
M.delete = function(picker, entry)
  local pattern = (picker.finder.filter.pattern or "")
  picker:close()
  if not entry then
    return
  else
  end
  local path = entry.text
  local function _15_(choice)
    if (choice == "Yes") then
      local ok_3f = pcall(utils.rm, path)
      if ok_3f then
        utils.info(("Deleted: " .. path))
      else
        utils.error(("Failed to delete: " .. path))
      end
      local function _17_()
        return M.open(pattern)
      end
      return vim.schedule(_17_)
    else
      return nil
    end
  end
  return utils["prompt-bool"](("Delete " .. path .. "?"), _15_)
end
M.copy = function(entry)
  if not entry then
    return
  else
  end
  local path = entry.text
  local password = utils.show(path)
  vim.fn.setreg("+", password)
  return utils.info(("Copied " .. path))
end
M.log = function()
  local snacks_picker = require("snacks.picker")
  return snacks_picker.git_log({cwd = utils["get-password-store-dir"]()})
end
local function auto_close_picker(action)
  local function _20_(picker, entry)
    picker:close()
    return action(entry)
  end
  return _20_
end
M.insert = function(picker)
  local pattern = picker.finder.filter.pattern
  picker:close()
  local function _21_(new_path)
    return M.edit(picker, {text = new_path})
  end
  return vim.ui.input({prompt = "New password's path", default = pattern}, _21_)
end
M.open = function(pattern)
  if not utils["verify-gpg-auth"]() then
    utils.debug("GPG key locked. Attempting to unlock...")
    if not utils["unlock-gpg-key"]() then
      utils.error("Failed to unlock GPG key.")
      return
    else
    end
  else
  end
  local ok_3f, snacks_picker = pcall(require, "snacks.picker")
  if not ok_3f then
    utils.error("snacks.nvim is required")
    return
  else
  end
  return snacks_picker.pick({title = "Password Store", pattern = pattern, items = utils["list-passwords"](), format = "text", layout = {preset = "select"}, win = {input = {keys = {["<c-r>"] = {"rename", mode = {"i", "n"}}, ["<c-d>"] = {"delete", mode = {"i", "n"}}, ["<c-e>"] = {"edit", mode = {"i", "n"}}, ["<c-i>"] = {"insert", mode = {"i", "n"}}, ["<c-l>"] = {"log", mode = {"i", "n"}}}}}, confirm = "copy", actions = {rename = M.rename, insert = M.insert, edit = M.edit, delete = M.delete, log = auto_close_picker(M.log), copy = auto_close_picker(M.copy)}})
end
return M
