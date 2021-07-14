-- Copyright 2021 Gregory Anders
--
-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any later
-- version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
--
-- You should have received a copy of the GNU General Public License along with
-- this program.  If not, see <https://www.gnu.org/licenses/>.

local pathsep = package.config:sub(1, 1)

-- Modified version of glob2regpat that does not match path separators on *.
-- Basically, this replaces single instances of * with the regex pattern [^/]*.
-- However, the star in the replacement pattern also gets interpreted by
-- glob2regpat, so we insert a placeholder, pass it through glob2regpat, then
-- replace the placeholder with the actual regex pattern
local function glob2regpat(glob)
	-- Replace {m..n} with [m-n]
	local tmp = glob:gsub("{(%d+)%.%.(%d+)}", "[%1-%2]")
	-- Replace single *'s with a placeholder
	tmp = vim.fn.substitute(tmp, "\\*\\@<!\\*\\*\\@!", "@@PLACEHOLDER@@", "g")

	return (string.gsub(vim.fn.glob2regpat(tmp), "@@PLACEHOLDER@@", "[^" .. pathsep .. "]*"))
end

local function dirname(path)
	return path:match(string.format("^(.+)%s[^%s]+", pathsep, pathsep)) or path
end

local function parse(filepath, config)
	local pat
	local opts = {}
	local confdir = dirname(config)
	local f = assert(io.open(config, "r"))

	for line in f:lines() do
		if line:find("^%s*[^ #;]") then
			local glob = string.match(line:match("%b[]") or "", "%[([^%]]+)")
			if glob then
				if glob:find(pathsep) then
					glob = confdir .. pathsep .. glob:gsub("^" .. pathsep, "")
				else
					glob = "**" .. pathsep .. glob
				end
				pat = vim.regex(glob2regpat(glob))
			else
				local key, val = line:match("^%s*([^:= ][^:=]-)%s*[:=]%s*(.-)%s*$")
				if key then
					key, val = key:lower(), val:lower()
					if key == "root" then
						opts.root = val == "true"
					elseif pat and pat:match_str(filepath) then
						opts[key] = val
					end
				end
			end
		end
	end

	f:close()

	return opts
end

local apply_option = {
	["charset"] = function(val)
		assert(vim.tbl_contains({ "utf-8", "utf-8-bom", "latin1", "utf-16be", "utf-16le" }, val))
		if val == "utf-8" then
			vim.bo.fileencoding = "utf-8"
			vim.bo.bomb = false
		elseif val == "utf-8-bom" then
			vim.bo.fileencoding = "utf-8"
			vim.bo.bomb = true
		else
			vim.bo.fileencoding = val
		end
	end,
	["end_of_line"] = function(val)
		vim.bo.fileformat = assert(({ lf = "unix", crlf = "dos", cr = "mac" })[val])
	end,
	["indent_style"] = function(val, opts)
		assert(val == "tab" or val == "space")
		vim.bo.expandtab = val == "space"
		if val == "tab" and not opts.indent_size then
			vim.bo.shiftwidth = 0
			vim.bo.softtabstop = 0
		end
	end,
	["indent_size"] = function(val, opts)
		if val == "tab" then
			vim.bo.shiftwidth = 0
			vim.bo.softtabstop = 0
		else
			local n = assert(tonumber(val))
			vim.bo.shiftwidth = n
			vim.bo.softtabstop = -1
			if not opts.tab_width then
				vim.bo.tabstop = n
			end
		end
	end,
	["tab_width"] = function(val)
		vim.bo.tabstop = assert(tonumber(val))
	end,
	["max_line_length"] = function(val)
		vim.bo.textwidth = assert(tonumber(val))
	end,
	["trim_trailing_whitespace"] = function(val)
		assert(val == "true" or val == "false")
		if val == "true" then
			vim.cmd("autocmd! editorconfig BufWritePre <buffer> lua require('editorconfig').trim_trailing_whitespace()")
		end
	end,
	["insert_final_newline"] = function(val)
		assert(val == "true" or val == "false")
		vim.bo.fixendofline = val == "true"
	end,
}

local M = {}

function M.config()
	if vim.bo.buftype ~= "" or not vim.bo.modifiable then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return
	end

	local opts = {}
	local curdir = dirname(path)
	while true do
		local config = curdir .. pathsep .. ".editorconfig"
		if vim.loop.fs_access(config, "R") then
			opts = vim.tbl_extend("keep", opts, parse(path, config))
			if opts.root then
				break
			end
		end

		local parent = dirname(curdir)
		if parent == curdir then
			break
		end
		curdir = parent
	end

	for opt, val in pairs(opts) do
		if val ~= "unset" and apply_option[opt] and not pcall(apply_option[opt], val, opts) then
			vim.api.nvim_err_writeln(string.format("editorconfig: invalid value for option %s: %s", opt, val))
		end
	end
end

function M.trim_trailing_whitespace()
	local view = vim.fn.winsaveview()
	vim.cmd("silent keepjumps keeppatterns %s/\\s\\+$//e")
	vim.fn.winrestview(view)
end

return M
