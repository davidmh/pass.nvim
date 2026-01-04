-- [nfnl] fnl/pass/module.fnl
local M = {}
M.define = function(mod_name, base)
  local loaded = package.loaded[mod_name]
  if (((type(loaded) == type(base)) or (nil == base)) and (nil ~= loaded) and ("number" ~= type(loaded))) then
    return loaded
  else
    return (base or {})
  end
end
return M
