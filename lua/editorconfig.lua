local pathsep = string.sub(package.config, 1, 1)
local apply = {}
apply.charset = function(val)
  assert(vim.tbl_contains({"utf-8", "utf-8-bom", "latin1", "utf-16be", "utf-16le"}, val))
  if ((val == "utf-8") or (val == "utf-8-bom")) then
    vim.bo.fileencoding = "utf-8"
    vim.bo.bomb = (val == "utf-8-bom")
    return nil
  else
    vim.bo.fileencoding = val
    return nil
  end
end
apply.end_of_line = function(val)
  vim.bo.fileformat = assert(({cr = "mac", crlf = "dos", lf = "unix"})[val])
  return nil
end
apply.indent_style = function(val, opts)
  assert(((val == "tab") or (val == "space")))
  vim.bo.expandtab = (val == "space")
  if ((val == "tab") and not opts.indent_size) then
    vim.bo.shiftwidth = 0
    vim.bo.softtabstop = 0
    return nil
  end
end
apply.indent_size = function(val, opts)
  if (val == "tab") then
    vim.bo.shiftwidth = 0
    vim.bo.softtabstop = 0
    return nil
  else
    local n = assert(tonumber(val))
    vim.bo.shiftwidth = n
    vim.bo.softtabstop = -1
    if not opts.tab_width then
      vim.bo.tabstop = n
      return nil
    end
  end
end
apply.tab_width = function(val)
  vim.bo.tabstop = assert(tonumber(val))
  return nil
end
apply.max_line_length = function(val)
  vim.bo.textwidth = assert(tonumber(val))
  return nil
end
apply.trim_trailing_whitespace = function(val)
  assert(((val == "true") or (val == "false")))
  if (val == "true") then
    return vim.api.nvim_command("autocmd! editorconfig BufWritePre <buffer> lua require('editorconfig').trim_trailing_whitespace()")
  end
end
apply.insert_final_newline = function(val)
  assert(((val == "true") or (val == "false")))
  vim.bo.fixendofline = (val == "true")
  return nil
end
local function glob2regpat(glob)
  local placeholder = "@@PLACEHOLDER@@"
  return string.gsub(vim.fn.glob2regpat(vim.fn.substitute(string.gsub(glob, "{(%d+)%.%.(%d+)}", "[%1-%2]"), "\\*\\@<!\\*\\*\\@!", placeholder, "g")), placeholder, ("[^" .. pathsep .. "]*"))
end
local function dirname(path)
  return (path:match(("^(.+)%s[^%s]+"):format(pathsep, pathsep)) or path)
end
local function parseline(line)
  if line:find("^%s*[^ #;]") then
    local _0_ = ((line:match("%b[]") or "")):match("%[([^%]]+)")
    if (nil ~= _0_) then
      local glob = _0_
      return glob, nil, nil
    else
      local _ = _0_
      local _1_, _2_ = line:match("^%s*([^:= ][^:=]-)%s*[:=]%s*(.-)%s*$")
      if ((nil ~= _1_) and (nil ~= _2_)) then
        local key = _1_
        local val = _2_
        return nil, key:lower(), val:lower()
      end
    end
  end
end
local function parse(filepath, config)
  local pat = nil
  local opts = {}
  do
    local confdir = dirname(config)
    local f = io.open(config)
    if f then
      for line in f:lines() do
        local _0_, _1_, _2_ = parseline(line)
        if (nil ~= _0_) then
          local glob = _0_
          local glob0
          if glob:find(pathsep) then
            glob0 = (confdir .. pathsep .. glob:gsub(("^" .. pathsep), ""))
          else
            glob0 = ("**" .. pathsep .. glob)
          end
          pat = vim.regex(glob2regpat(glob0))
        elseif ((_0_ == nil) and (nil ~= _1_) and (nil ~= _2_)) then
          local key = _1_
          local val = _2_
          if (key == "root") then
            opts["root"] = (val == "true")
          elseif (pat and pat:match_str(filepath)) then
            opts[key] = val
          end
        end
      end
      f:close()
    end
  end
  return opts
end
local function config()
  if ((vim.bo.buftype == "") and vim.bo.modifiable) then
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(bufnr)
    if (path ~= "") then
      local done_3f = false
      local opts = {}
      local curdir = dirname(path)
      while not done_3f do
        local config0 = (curdir .. pathsep .. ".editorconfig")
        opts = vim.tbl_extend("keep", opts, parse(path, config0))
        if opts.root then
          done_3f = true
        else
          local parent = dirname(curdir)
          if (parent == curdir) then
            done_3f = true
          else
            curdir = parent
          end
        end
      end
      for opt, val in pairs(opts) do
        if (val ~= "unset") then
          local _0_ = apply[opt]
          if (nil ~= _0_) then
            local func = _0_
            if not pcall(func, val, opts) then
              vim.notify(("editorconfig: invalid value for option %s: %s"):format(opt, val), vim.log.levels.ERROR)
            end
          end
        end
      end
      return nil
    end
  end
end
local function trim_trailing_whitespace()
  local view = vim.fn.winsaveview()
  vim.api.nvim_command("silent keepjumps keeppatterns %s/\\s\\+$//e")
  return vim.fn.winrestview(view)
end
return {config = config, trim_trailing_whitespace = trim_trailing_whitespace}
