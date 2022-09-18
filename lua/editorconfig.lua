local is_win_3f = (vim.fn.has("win32") == 1)
local properties = {}
local function assert(v, message)
  return (v or error(message, 0))
end
local function warn(msg)
  return vim.notify(msg, vim.log.levels.WARN, {title = "editorconfig"})
end
properties.charset = function(bufnr, val)
  assert(vim.tbl_contains({"utf-8", "utf-8-bom", "latin1", "utf-16be", "utf-16le"}, val), "charset must be one of 'utf-8', 'utf-8-bom', 'latin1', 'utf-16be', or 'utf-16le'")
  if ((val == "utf-8") or (val == "utf-8-bom")) then
    vim.bo[bufnr]["fileencoding"] = "utf-8"
    vim.bo[bufnr]["bomb"] = (val == "utf-8-bom")
    return nil
  else
    vim.bo[bufnr]["fileencoding"] = val
    return nil
  end
end
properties.end_of_line = function(bufnr, val)
  vim.bo[bufnr]["fileformat"] = assert(({lf = "unix", crlf = "dos", cr = "mac"})[val], "end_of_line must be one of 'lf', 'crlf', or 'cr'")
  return nil
end
properties.indent_style = function(bufnr, val, opts)
  assert(((val == "tab") or (val == "space")), "indent_style must be either 'tab' or 'space'")
  do end (vim.bo)[bufnr]["expandtab"] = (val == "space")
  if ((val == "tab") and not opts.indent_size) then
    vim.bo[bufnr]["shiftwidth"] = 0
    vim.bo[bufnr]["softtabstop"] = 0
    return nil
  else
    return nil
  end
end
properties.indent_size = function(bufnr, val, opts)
  if (val == "tab") then
    vim.bo[bufnr]["shiftwidth"] = 0
    vim.bo[bufnr]["softtabstop"] = 0
    return nil
  else
    local n = assert(tonumber(val), "indent_size must be a number")
    do end (vim.bo)[bufnr]["shiftwidth"] = n
    vim.bo[bufnr]["softtabstop"] = -1
    if not opts.tab_width then
      vim.bo[bufnr]["tabstop"] = n
      return nil
    else
      return nil
    end
  end
end
properties.tab_width = function(bufnr, val)
  vim.bo[bufnr]["tabstop"] = assert(tonumber(val), "tab_width must be a number")
  return nil
end
properties.max_line_length = function(bufnr, val)
  local _5_ = tonumber(val)
  if (nil ~= _5_) then
    local n = _5_
    vim.bo[bufnr]["textwidth"] = n
    return nil
  elseif (_5_ == nil) then
    if (val == "off") then
      vim.bo[bufnr]["textwidth"] = 0
      return nil
    else
      return error("max_line_length must be a number or 'off'", 0)
    end
  else
    return nil
  end
end
properties.trim_trailing_whitespace = function(bufnr, val)
  assert(((val == "true") or (val == "false")), "trim_trailing_whitespace must be either 'true' or 'false'")
  if (val == "true") then
    return vim.api.nvim_command("autocmd! editorconfig BufWritePre <buffer> lua require('editorconfig').trim_trailing_whitespace()")
  else
    return nil
  end
end
properties.insert_final_newline = function(bufnr, val)
  assert(((val == "true") or (val == "false")), "insert_final_newline must be either 'true' or 'false'")
  if (val ~= "true") then
    vim.bo[bufnr]["fixendofline"] = false
    vim.bo[bufnr]["endofline"] = false
    return nil
  else
    return nil
  end
end
local function glob2regpat(glob)
  local placeholder = "@@PLACEHOLDER@@"
  return string.gsub(vim.fn.glob2regpat(vim.fn.substitute(string.gsub(glob, "{(%d+)%.%.(%d+)}", "[%1-%2]"), "\\*\\@<!\\*\\*\\@!", placeholder, "g")), placeholder, "[^/]*")
end
local function convert_pathseps(path)
  if is_win_3f then
    return path:gsub("\\", "/")
  else
    return path
  end
end
local function dirname(path)
  return vim.fn.fnamemodify(path, ":h")
end
local function parse_line(line)
  if line:find("^%s*[^ #;]") then
    local _11_ = ((line:match("%b[]") or "")):match("^%s*%[(.*)%]%s*$")
    if (nil ~= _11_) then
      local glob = _11_
      return glob, nil, nil
    elseif true then
      local _ = _11_
      local _12_, _13_ = line:match("^%s*([^:= ][^:=]-)%s*[:=]%s*(.-)%s*$")
      if ((nil ~= _12_) and (nil ~= _13_)) then
        local key = _12_
        local val = _13_
        return nil, key:lower(), val:lower()
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function parse(filepath, dir)
  local pat = nil
  local opts = {}
  do
    local _17_ = io.open((dir .. "/.editorconfig"))
    if (nil ~= _17_) then
      local f = _17_
      local _ = f
      local function close_handlers_8_auto(ok_9_auto, ...)
        _:close()
        if ok_9_auto then
          return ...
        else
          return error(..., 0)
        end
      end
      local function _19_()
        for line in f:lines() do
          local _20_, _21_, _22_ = parse_line(line)
          if (nil ~= _20_) then
            local glob = _20_
            local glob0
            if glob:find("/") then
              glob0 = (dir .. "/" .. glob:gsub("^/", ""))
            else
              glob0 = ("**/" .. glob)
            end
            local _24_, _25_ = pcall(glob2regpat, glob0)
            if ((_24_ == true) and (nil ~= _25_)) then
              local regpat = _25_
              pat = vim.regex(regpat)
            elseif ((_24_ == false) and (nil ~= _25_)) then
              local err = _25_
              pat = nil
              warn(("editorconfig: Error occurred while parsing glob pattern '%s': %s"):format(glob0, err))
            else
            end
          elseif ((_20_ == nil) and (nil ~= _21_) and (nil ~= _22_)) then
            local key = _21_
            local val = _22_
            if (key == "root") then
              opts["root"] = (val == "true")
            elseif (pat and pat:match_str(filepath)) then
              opts[key] = val
            else
            end
          else
          end
        end
        return nil
      end
      close_handlers_8_auto(_G.xpcall(_19_, (package.loaded.fennel or debug).traceback))
    else
    end
  end
  return opts
end
local function config(bufnr)
  local bufnr0 = (bufnr or vim.api.nvim_get_current_buf())
  local path = convert_pathseps(vim.api.nvim_buf_get_name(bufnr0))
  if ((vim.bo[bufnr0].buftype == "") and vim.bo[bufnr0].modifiable and (path ~= "")) then
    local opts = {}
    local curdir = dirname(path)
    local done_3f = false
    while not done_3f do
      for k, v in pairs(parse(path, curdir)) do
        if (opts[k] == nil) then
          opts[k] = v
        else
        end
      end
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
    local applied = {}
    for opt, val in pairs(opts) do
      if (val ~= "unset") then
        local _33_ = properties[opt]
        if (nil ~= _33_) then
          local func = _33_
          local _34_, _35_ = pcall(func, bufnr0, val, opts)
          if (_34_ == true) then
            applied[opt] = val
          elseif ((_34_ == false) and (nil ~= _35_)) then
            local err = _35_
            warn(("editorconfig: invalid value for option %s: %s. %s"):format(opt, val, err))
          else
          end
        else
        end
      else
      end
    end
    vim.b[bufnr0]["editorconfig"] = applied
    return nil
  else
    return nil
  end
end
local function trim_trailing_whitespace()
  local view = vim.fn.winsaveview()
  vim.api.nvim_command("silent keepjumps keeppatterns %s/\\s\\+$//e")
  return vim.fn.winrestview(view)
end
return {config = config, trim_trailing_whitespace = trim_trailing_whitespace, properties = properties}
