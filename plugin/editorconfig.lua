-- Copyright 2022 Gregory Anders
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

if vim.g.loaded_editorconfig then
    return
end
vim.g.loaded_editorconfig = 1

-- Ensure the editorconfig autocommand is created as late as possible to ensure
-- that it runs *after* every other BufRead autocommand (within reason, there
-- is nothing we can do about autocommands created in a lazy loaded plugin) by
-- defining it just before the very first redraw. This is a hack. Sue me.
local ns = vim.api.nvim_create_namespace("")
vim.api.nvim_set_decoration_provider(ns, {
    on_start = function()
        local id = vim.api.nvim_create_augroup("editorconfig", {})
        vim.api.nvim_create_autocmd({"BufNewFile", "BufRead", "BufFilePost"}, {
            group = id,
            callback = function(args)
                require("editorconfig").config(args.buf)
            end,
        })
        vim.api.nvim_set_decoration_provider(ns, {})
        return false
    end,
})
