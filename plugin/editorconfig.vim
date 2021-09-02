" Copyright 2021 Gregory Anders
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

if exists('g:loaded_editorconfig') || !has('nvim')
    finish
endif
let g:loaded_editorconfig = 1

function! s:load(...)
    for buf in nvim_list_bufs()
        call luaeval('require("editorconfig").config(_A)', buf)
    endfor
    autocmd! editorconfig BufNewFile,BufRead,BufFilePost * lua require('editorconfig').config()
endfunction

augroup editorconfig
    if v:vim_did_enter
        call s:load()
    else
        autocmd VimEnter * ++nested call s:load()
    endif
augroup END
