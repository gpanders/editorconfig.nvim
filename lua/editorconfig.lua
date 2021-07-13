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

local function invalid(opt, val)
	vim.api.nvim_err_writeln(string.format("editorconfig: invalid value for option %s: %s", opt, val))
end

-- Modified version of glob2regpat that does not match path separators on *.
-- Basically, this replaces single instances of * with the regex pattern [^/]*.
-- However, the star in the replacement pattern also gets interpreted by
-- glob2regpat, so we insert a placeholder, pass it through glob2regpat, then
-- replace the placeholder with the actual regex pattern
local function glob2regpat(glob)
	-- Replace {m..n} with [m-n]
	local g = glob:gsub("{(%d+)%.%.(%d+)}", "[%1-%2]")
	g = vim.fn.substitute(g, "\\*\\@<!\\*\\*\\@!", "@@PLACEHOLDER@@", "g")
	return vim.fn.substitute(vim.fn.glob2regpat(g), "@@PLACEHOLDER@@", "[^" .. pathsep .. "]*", "g")
end

local function dirname(path)
	return path:match(string.format("^(.+)%s[^%s]+", pathsep, pathsep)) or path
end

local function apply(opts)
	for opt, val in pairs(opts) do
		if opt == "charset" then
			if val == "utf-8" then
				vim.bo.fileencoding = "utf-8"
				vim.bo.bomb = false
			elseif val == "utf-8-bom" then
				vim.bo.fileencoding = "utf-8"
				vim.bo.bomb = true
			elseif vim.tbl_contains({
				"latin1",
				"utf-16be",
				"utf-16le",
			}, val) then
				vim.bo.fileencoding = val
			else
				invalid(opt, val)
			end
		elseif opt == "end_of_line" then
			if val == "lf" then
				vim.bo.fileformat = "unix"
			elseif val == "crlf" then
				vim.bo.fileformat = "dos"
			elseif val == "cr" then
				vim.bo.fileformat = "mac"
			else
				invalid(opt, val)
			end
		elseif opt == "indent_style" then
			if val == "tab" then
				vim.bo.expandtab = false
				if not opts.indent_size then
					vim.bo.shiftwidth = 0
					vim.bo.softtabstop = 0
				end
			elseif val == "space" then
				vim.bo.expandtab = true
			else
				invalid(opt, val)
			end
		elseif opt == "indent_size" then
			if val == "tab" then
				vim.bo.shiftwidth = 0
				vim.bo.softtabstop = 0
			else
				local n = tonumber(val)
				if n then
					vim.bo.shiftwidth = n
					vim.bo.softtabstop = -1
					if not opts.tab_width then
						vim.bo.tabstop = n
					end
				else
					invalid(opt, val)
				end
			end
		elseif opt == "tab_width" then
			local n = tonumber(val)
			if n then
				vim.bo.tabstop = n
			else
				invalid(opt, val)
			end
		elseif opt == "max_line_length" then
			local n = tonumber(val)
			if n then
				vim.bo.textwidth = n
			else
				invalid(opt, val)
			end
		elseif opt == "trim_trailing_whitespace" then
			if val == "true" then
				vim.cmd("autocmd! editorconfig BufWritePre <buffer> lua require('editorconfig').trim_trailing_whitespace()")
			end
		elseif opt == "insert_final_newline" then
			if val == "true" then
				vim.bo.fixendofline = true
			elseif val == "false" then
				vim.bo.fixendofline = false
			else
				invalid(opt, val)
			end
		end
	end
end

local function parse(filepath, config)
	local pat
	local opts = {}
	local confdir = dirname(config)

	for _, line in ipairs(vim.fn.readfile(config)) do
		if not line:find("^%s*$") and not line:find("^%s*[#;]") then
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
					val = val:lower()
					if key == "root" then
						opts.root = val == "true"
					elseif pat and pat:match_str(filepath) then
						opts[key] = val
					end
				end
			end
		end
	end

	return opts
end

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

	apply(opts)
end

function M.trim_trailing_whitespace()
	local view = vim.fn.winsaveview()
	vim.cmd("silent keepjumps keeppatterns %s/\\s\\+$//e")
	vim.fn.winrestview(view)
end

return M
