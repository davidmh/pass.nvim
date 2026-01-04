-- [nfnl] fnl/pass/utils.fnl
local _local_1_ = require("pass.module")
local define = _local_1_.define
local M = define("pass.utils", {})
local notification_chrome = {icon = "\240\159\155\130", title = "pass.nvim"}
local function read_lines(path)
  if (vim.fn.filereadable(path) == 1) then
    return vim.fn.readfile(path)
  else
    return {}
  end
end
local function get_gpg_ids()
  local store_dir = M["get-password-store-dir"]()
  return read_lines((store_dir .. ".gpg-id"))
end
local function get_keygrips(gpg_id)
  local result = vim.system({"gpg", "--list-secret-keys", "--with-colons", gpg_id}, {text = true}):wait()
  if (result.code == 0) then
    local grips = {}
    for line in result.stdout:gmatch("[^\r\n]+") do
      if line:match("^grp:") then
        local fields = vim.split(line, ":")
        table.insert(grips, fields[10])
      else
      end
    end
    return grips
  else
    return {}
  end
end
local function is_cached_3f(keygrip)
  local result = vim.system({"gpg-connect-agent", ("KEYINFO " .. keygrip), "/bye"}, {text = true}):wait()
  if (result.code == 0) then
    local lines = vim.split(vim.trim(result.stdout), "\n")
    for _, line in ipairs(lines) do
      local case_5_ = vim.split(line, " ")
      if ((_G.type(case_5_) == "table") and (case_5_[1] == "S") and (case_5_[2] == "KEYINFO") and true and true and true and true and (case_5_[7] == "1")) then
        local _0 = case_5_[3]
        local _1 = case_5_[4]
        local _2 = case_5_[5]
        local _3 = case_5_[6]
        return true
      else
      end
    end
  else
  end
  return false
end
M["verify-gpg-auth"] = function()
  local ids = get_gpg_ids()
  if vim.tbl_isempty(ids) then
  else
    for _, id in ipairs(ids) do
      local grips = get_keygrips(id)
      for _0, grip in ipairs(grips) do
        if is_cached_3f(grip) then
          return true
        else
        end
      end
    end
  end
  return false
end
M["unlock-gpg-key"] = function()
  local ids = get_gpg_ids()
  if vim.tbl_isempty(ids) then
    return false
  else
    local key_id = vim.trim(ids[1])
    local result = vim.system({"gpg", "--clearsign", "--quiet", "--no-tty", "--default-key", key_id}, {text = true, stdin = "unlock check"}):wait()
    return (result.code == 0)
  end
end
M["get-password-store-dir"] = function()
  local dir = (vim.env.PASSWORD_STORE_DIR or (vim.env.HOME .. "/.password-store/"))
  if (dir:sub(-1) == "/") then
    return dir
  else
    return (dir .. "/")
  end
end
M["list-passwords"] = function()
  local store_dir = M["get-password-store-dir"]()
  local extension = ".gpg$"
  local files
  local function _12_(name)
    return name:match(extension)
  end
  files = vim.fs.find(_12_, {path = store_dir, limit = math.huge})
  local function _13_(file)
    return {text = string.gsub(string.sub(file, (#store_dir + 1), #file), extension, "")}
  end
  return vim.tbl_map(_13_, files)
end
local function run(_14_)
  local cmd = _14_.cmd
  local stdin = _14_.stdin
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
M.debug = function(msg)
  if vim.g.pass_debug then
    return vim.notify(msg, vim.log.levels.ERROR, notification_chrome)
  else
    return nil
  end
end
M["prompt-bool"] = function(question, action)
  return vim.ui.select({"Yes", "No"}, {prompt = question}, action)
end
M.test = function()
  return M.info("hello")
end
return M
