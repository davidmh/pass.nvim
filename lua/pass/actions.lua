-- [nfnl] fnl/pass/actions.fnl
local utils = require("pass.utils")
local M = {}
local function update_password_on_leave(_1_)
  local buf = _1_.buf
  local old_content = _1_["old-content"]
  local path = _1_.path
  local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local new_content = table.concat(new_lines, "\n")
  if (vim.trim(new_content) == vim.trim(old_content)) then
    utils.debug("The password didn't change")
    return
  else
  end
  if (new_content == "") then
    M.delete({text = path})
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
M.edit = function(entry)
  if not entry then
    return
  else
  end
  local path = entry.text
  local ok_3f, result = pcall(utils.show, path)
  if not ok_3f then
    utils.error(("Failed to read: " .. path))
    return
  else
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", "pass", {scope = "local", buf = buf})
  vim.api.nvim_set_option_value("bufhidden", "wipe", {scope = "local", buf = buf})
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, "\n"))
  local width = math.min(80, (vim.o.columns - 4))
  local height = math.min(20, (vim.o.lines - 4))
  local row = math.floor(((vim.o.lines - height) / 2))
  local col = math.floor(((vim.o.columns - width) / 2))
  local win_config = {relative = "editor", width = width, height = height, row = row, col = col, style = "minimal", border = "rounded", title = (" Edit " .. path .. " "), title_pos = "center"}
  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.api.nvim_set_option_value("winblend", 0, {win = win})
  utils["disable-backup-options"]()
  local function _7_()
    return update_password_on_leave({buf = buf, path = path, ["old-content"] = result})
  end
  return vim.api.nvim_create_autocmd("BufWinLeave", {buffer = buf, callback = _7_})
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
    M.open(pattern)
    return picker:close()
  end
  return vim.ui.input({prompt = ("Rename " .. old_path), default = old_path}, on_rename)
end
M.delete = function(entry)
  if not entry then
    return
  else
  end
  local path = entry.text
  local function _12_(choice)
    if (choice == "Yes") then
      local ok_3f = pcall(utils.rm, path)
      if ok_3f then
        return utils.info(("Deleted: " .. path))
      else
        return utils.error(("Failed to delete: " .. path))
      end
    else
      return nil
    end
  end
  return vim.ui.select({"Yes", "No"}, {prompt = ("Delete " .. path .. "?")}, _12_)
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
  local function _16_(picker, entry)
    picker:close()
    return action(entry)
  end
  return _16_
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
  return snacks_picker.pick({title = "Password Store", pattern = pattern, items = utils["list-passwords"](), format = "text", layout = {preset = "select"}, win = {input = {keys = {["<c-r>"] = {"rename", mode = {"i", "n"}}, ["<c-d>"] = {"delete", mode = {"i", "n"}}, ["<c-e>"] = {"edit", mode = {"i", "n"}}, ["<c-l>"] = {"log", mode = {"i", "n"}}}}}, confirm = "copy", actions = {rename = M.rename, delete = auto_close_picker(M.delete), edit = auto_close_picker(M.edit), log = auto_close_picker(M.log), copy = auto_close_picker(M.copy)}})
end
return M
