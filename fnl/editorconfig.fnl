; Copyright 2022 Gregory Anders
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

(local properties {})

(fn assert [v message]
  "Modified version of the builtin assert that does not include error position information"
  (or v (error message 0)))

(fn warn [msg]
  ; 'title' is supported by nvim-notify
  (vim.notify msg vim.log.levels.WARN {:title :editorconfig}))

; TODO: Inline this function when trim_trailing_whitespace is removed
(fn trim-trailing-whitespace []
  (let [view (vim.fn.winsaveview)]
    (vim.api.nvim_command "silent! undojoin")
    (vim.api.nvim_command "silent keepjumps keeppatterns %s/\\s\\+$//e")
    (vim.fn.winrestview view)))

(fn properties.charset [bufnr val]
  (assert (vim.tbl_contains [:utf-8 :utf-8-bom :latin1 :utf-16be :utf-16le] val)
          "charset must be one of 'utf-8', 'utf-8-bom', 'latin1', 'utf-16be', or 'utf-16le'")
  (if (or (= val :utf-8) (= val :utf-8-bom))
      (do
        (tset vim.bo bufnr :fileencoding :utf-8)
        (tset vim.bo bufnr :bomb (= val :utf-8-bom)))
      (tset vim.bo bufnr :fileencoding val)))

(fn properties.end_of_line [bufnr val]
  (tset vim.bo bufnr :fileformat (assert (. {:lf :unix :crlf :dos :cr :mac} val)
                                         "end_of_line must be one of 'lf', 'crlf', or 'cr'")))

(fn properties.indent_style [bufnr val opts]
  (assert (or (= val :tab) (= val :space))
          "indent_style must be either 'tab' or 'space'")
  (tset vim.bo bufnr :expandtab (= val :space))
  (when (and (= val :tab) (not opts.indent_size))
    (tset vim.bo bufnr :shiftwidth 0)
    (tset vim.bo bufnr :softtabstop 0)))

(fn properties.indent_size [bufnr val opts]
  (if (= val :tab)
      (do
        (tset vim.bo bufnr :shiftwidth 0)
        (tset vim.bo bufnr :softtabstop 0))
      (let [n (assert (tonumber val) "indent_size must be a number")]
        (tset vim.bo bufnr :shiftwidth n)
        (tset vim.bo bufnr :softtabstop -1)
        (when (not opts.tab_width)
          (tset vim.bo bufnr :tabstop n)))))

(fn properties.tab_width [bufnr val]
  (tset vim.bo bufnr :tabstop (assert (tonumber val) "tab_width must be a number")))

(fn properties.max_line_length [bufnr val]
  (match (tonumber val)
    n (tset vim.bo bufnr :textwidth n)
    nil (if (= val :off)
            (tset vim.bo bufnr :textwidth 0)
            (error "max_line_length must be a number or 'off'" 0))))

(fn properties.trim_trailing_whitespace [bufnr val]
  (assert (or (= val :true) (= val :false)) "trim_trailing_whitespace must be either 'true' or 'false'")
  (when (= val :true)
    (if (= (vim.fn.has :nvim-0.7) 1)
        (vim.api.nvim_create_autocmd :BufWritePre {:group :editorconfig
                                                   :buffer bufnr
                                                   :callback trim-trailing-whitespace})
        (vim.cmd (: "autocmd editorconfig BufWritePre <buffer=%d> lua require('editorconfig').trim_trailing_whitespace()"
                    :format bufnr)))))

(fn properties.insert_final_newline [bufnr val]
  (assert (or (= val :true) (= val :false)) "insert_final_newline must be either 'true' or 'false'")
  (when (not= val :true)
    (tset vim.bo bufnr :fixendofline false)
    (tset vim.bo bufnr :endofline false)))

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
      (path:gsub "\\" "/")
      path))

(fn dirname [path]
  (vim.fn.fnamemodify path ":h"))

(fn parse-line [line]
  (when (line:find "^%s*[^ #;]")
    (match (: (or (line:match "%b[]") "") :match "^%s*%[(.*)%]%s*$")
      glob (values glob nil nil)
      _ (match (line:match "^%s*([^:= ][^:=]-)%s*[:=]%s*(.-)%s*$")
          (key val) (values nil (key:lower) (val:lower))))))

(fn parse [filepath dir]
  (var pat nil)
  (local opts {})
  (match (io.open (.. dir "/.editorconfig"))
    f (with-open [_ f]
        (each [line (f:lines)]
          (match (parse-line line)
            glob (let [glob (if (glob:find "/")
                                (.. dir "/" (glob:gsub "^/" ""))
                                (.. "**/" glob))]
                   (match (pcall glob2regpat glob)
                     (true regpat) (set pat (vim.regex regpat))
                     (false err) (do
                                   (set pat nil)
                                   (warn (: "editorconfig: Error occurred while parsing glob pattern '%s': %s" :format glob err)))))
            (nil key val) (if (= key :root)
                              (tset opts :root (= val :true))
                              (and pat (pat:match_str filepath))
                              (tset opts key val))))))
  opts)

(fn config [bufnr]
  (let [bufnr (or bufnr (vim.api.nvim_get_current_buf))
        path (-> bufnr vim.api.nvim_buf_get_name convert-pathseps)]
    (when (and (= (. vim.bo bufnr :buftype) "") (. vim.bo bufnr :modifiable) (not= path ""))
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
      (var applied {})
      (each [opt val (pairs opts)]
        (when (not= val :unset)
          (match (. properties opt)
            func (match (pcall func bufnr val opts)
                   true (tset applied opt val)
                   (false err) (warn (: "editorconfig: invalid value for option %s: %s. %s" :format opt val err))))))
      (tset vim.b bufnr :editorconfig applied))))

(fn trim_trailing_whitespace []
  (when (= (vim.fn.has :nvim-0.7) 1)
    (vim.notify_once (debug.traceback "editorconfig.nvim: trim_trailing_whitespace() is deprecated and will soon be removed" 2)
                     vim.log.levels.WARN))
  (trim-trailing-whitespace))

{: config
 : trim_trailing_whitespace
 : properties}
