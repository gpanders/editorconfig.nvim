; Copyright 2021 Gregory Anders
;
; SPDX-License-Identifier: GPL-3.0-or-later
;
; This program is free software: you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation, either version 3 of the License, or (at your option) any later
; version.
;
; This program is distributed in the hope that it will be useful, but WITHOUT
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
; details.
;
; You should have received a copy of the GNU General Public License along with
; this program.  If not, see <https://www.gnu.org/licenses/>.

(local is-win? (= (vim.fn.has :win32) 1))

(local apply {})

(macro autocmd [event action]
  `(vim.api.nvim_command
    ,(string.format "autocmd! editorconfig %s <buffer> %s" event action)))

(fn apply.charset [val]
  (assert (vim.tbl_contains [:utf-8 :utf-8-bom :latin1 :utf-16be :utf-16le] val))
  (if (or (= val :utf-8) (= val :utf-8-bom))
      (do
        (set vim.bo.fileencoding :utf-8)
        (set vim.bo.bomb (= val :utf-8-bom)))
      (set vim.bo.fileencoding val)))

(fn apply.end_of_line [val]
  (set vim.bo.fileformat (assert (. {:lf :unix :crlf :dos :cr :mac} val))))

(fn apply.indent_style [val opts]
  (assert (or (= val :tab) (= val :space)))
  (set vim.bo.expandtab (= val :space))
  (when (and (= val :tab) (not opts.indent_size))
    (set vim.bo.shiftwidth 0)
    (set vim.bo.softtabstop 0)))

(fn apply.indent_size [val opts]
  (if (= val :tab)
      (do
        (set vim.bo.shiftwidth 0)
        (set vim.bo.softtabstop 0))
      (let [n (assert (tonumber val))]
        (set vim.bo.shiftwidth n)
        (set vim.bo.softtabstop -1)
        (when (not opts.tab_width)
          (set vim.bo.tabstop n)))))

(fn apply.tab_width [val]
  (set vim.bo.tabstop (assert (tonumber val))))

(fn apply.max_line_length [val]
  (set vim.bo.textwidth (assert (tonumber val))))

(fn apply.trim_trailing_whitespace [val]
  (assert (or (= val :true) (= val :false)))
  (when (= val :true)
    (autocmd :BufWritePre
             "lua require('editorconfig').trim_trailing_whitespace()")))

(fn apply.insert_final_newline [val]
  (assert (or (= val :true) (= val :false)))
  (when (not= val :true)
    (set vim.bo.fixendofline false)
    (set vim.bo.endofline false)))

; Modified version of glob2regpat that does not match path separators on *.
; Basically, this replaces single instances of * with the regex pattern [^/]*.
; However, the star in the replacement pattern also gets interpreted by
; glob2regpat, so we insert a placeholder, pass it through glob2regpat, then
; replace the placeholder with the actual regex pattern
(fn glob2regpat [glob]
  (local placeholder "@@PLACEHOLDER@@")
  (-> glob
      (string.gsub "{(%d+)%.%.(%d+)}" "[%1-%2]")
      (vim.fn.substitute "\\*\\@<!\\*\\*\\@!" placeholder :g)
      (vim.fn.glob2regpat)
      (string.gsub placeholder "[^/]*")))

(fn convert-pathseps [path]
  (if is-win?
      (path:gsub "/" "\\")
      path))

(fn dirname [path]
  (vim.fn.fnamemodify path ":h"))

(fn parseline [line]
  (when (line:find "^%s*[^ #;]")
    (match (: (or (line:match "%b[]") "") :match "%[([^%]]+)")
      glob (values glob nil nil)
      _ (match (line:match "^%s*([^:= ][^:=]-)%s*[:=]%s*(.-)%s*$")
          (key val) (values nil (key:lower) (val:lower))))))

(fn parse [filepath dir]
  (var pat nil)
  (local opts {})
  (let [f (io.open (.. dir "/.editorconfig"))]
    (when f
      (each [line (f:lines)]
        (match (parseline line)
          glob (let [glob (if (glob:find "/")
                              (.. dir "/" (glob:gsub "^/" ""))
                              (.. "**/" glob))]
                 (-> glob
                     (glob2regpat)
                     (convert-pathseps)
                     (vim.regex)
                     (->> (set pat))))
          (nil key val) (if (= key :root)
                            (tset opts :root (= val :true))
                            (and pat (pat:match_str filepath))
                            (tset opts key val))))
      (f:close)))
  opts)

(fn config [bufnr]
  (when (and (= vim.bo.buftype "") vim.bo.modifiable)
    (let [bufnr (if (and bufnr (not= bufnr 0))
                    bufnr
                    (vim.api.nvim_get_current_buf))
          path (vim.api.nvim_buf_get_name bufnr)]
      (when (not= path "")
        (local opts {})
        (var curdir (dirname path))
        (var done? false)
        (while (not done?)
          (each [k v (pairs (parse path curdir))]
            (when (= (. opts k) nil)
              (tset opts k v)))
          (if opts.root
              (set done? true)
              (let [parent (dirname curdir)]
                (if (= parent curdir)
                    (set done? true)
                    (set curdir parent)))))
        (each [opt val (pairs opts)]
          (when (not= val :unset)
            (match (. apply opt)
              func (when (not (pcall func val opts))
                     (vim.notify
                       (: "editorconfig: invalid value for option %s: %s" :format opt val)
                       vim.log.levels.WARN)))))))))

(fn trim_trailing_whitespace []
  (let [view (vim.fn.winsaveview)]
    (vim.api.nvim_command "silent keepjumps keeppatterns %s/\\s\\+$//e")
    (vim.fn.winrestview view)))

{: config : trim_trailing_whitespace}
