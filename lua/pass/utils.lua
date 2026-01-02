-- [nfnl] fnl/pass/utils.fnl
local M = {}
local notification_chrome = {icon = "\240\159\155\130", title = "pass.nvim"}
M["get-password-store-dir"] = function()
  return (vim.env.PASSWORD_STORE_DIR or (vim.env.HOME .. "/.password-store/"))
end
M["list-passwords"] = function()
  local store_dir = M["get-password-store-dir"]()
  local extension = ".gpg$"
  local files
  local function _1_(name)
    return name:match(extension)
  end
  files = vim.fs.find(_1_, {path = store_dir, limit = math.huge})
  local function _2_(file)
    return {text = string.gsub(string.sub(file, (#store_dir + 1), #file), extension, "")}
  end
  return vim.tbl_map(_2_, files)
end
local function run(_3_)
  local cmd = _3_.cmd
  local stdin = _3_.stdin
  local result = vim.system(cmd, {text = true, stdin = stdin}):wait()
  if (result.code == 0) then
    return result.stdout:gsub("\n$", "")
  else
    return error(result.stderr)
  end
end
M.show = function(path)
  return run({cmd = {"pass", "show", path}})
end
M["save-content"] = function(path, content)
  return run({cmd = {"pass", "insert", "-m", "-f", path}, stdin = content})
end
M.mv = function(old_name, new_name)
  return run({cmd = {"pass", "mv", old_name, new_name}})
end
M.rm = function(path)
  return run({cmd = {"pass", "rm", "-f", path}})
end
M["disable-backup-options"] = function()
  vim.opt_local.backup = false
  vim.opt_local.writebackup = false
  vim.opt_local.swapfile = false
  vim.opt_local.shada = ""
  vim.opt_local.undofile = false
  vim.opt_local.shelltemp = false
  vim.opt_local.history = 0
  vim.opt_local.modeline = false
  return nil
end
M.info = function(msg)
  return vim.notify(msg, vim.log.levels.INFO, notification_chrome)
end
M.error = function(msg)
  return vim.notify(msg, vim.log.levels.ERROR, notification_chrome)
end
return M
