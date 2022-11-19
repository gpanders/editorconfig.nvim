" Copyright 2022 Gregory Anders
"
" SPDX-License-Identifier: GPL-3.0-or-later
"
" This program is free software: you can redistribute it and/or modify it under
" the terms of the GNU General Public License as published by the Free Software
" Foundation, either version 3 of the License, or (at your option) any later
" version.
"
" This program is distributed in the hope that it will be useful, but WITHOUT
" ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
" FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
" details.
"
" You should have received a copy of the GNU General Public License along with
" this program.  If not, see <https://www.gnu.org/licenses/>.

if exists('g:loaded_editorconfig')
    finish
endif
let g:loaded_editorconfig = 1

augroup editorconfig
    autocmd!
    autocmd BufNewFile,BufRead,BufFilePost * lua require('editorconfig').config(tonumber(vim.fn.expand('<abuf>')))
augroup END
