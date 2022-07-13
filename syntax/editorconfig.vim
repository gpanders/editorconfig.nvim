runtime! syntax/dosini.vim
unlet! b:current_syntax

syntax match editorconfigInvalidProperty "^\s*\zs\w\+\ze\s*="
syntax keyword editorconfigProperty root charset end_of_line indent_size indent_style insert_final_newline max_line_length tab_width trim_trailing_whitespace

for s:prop in get(g:, 'editorconfig_properties', [])
    exec 'syntax keyword editorconfigProperty ' .. s:prop
endfor
unlet! s:prop

hi def link editorconfigInvalidProperty Error
hi def link editorconfigProperty dosiniLabel

let b:current_syntax = 'editorconfig'
