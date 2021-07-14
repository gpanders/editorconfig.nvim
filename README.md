# editorconfig.nvim

EditorConfig plugin for Neovim written in Lua.

editorconfig.nvim is tested against [editorconfig-plugin-tests][]. It does not
use [editorconfig-core-lua][] as that library requires Lua 5.2 or later, while
Neovim currently only supports Lua 5.1. Instead, the core is implemented
directly.

[editorconfig-plugin-tests]: https://github.com/editorconfig/editorconfig-plugin-tests
[editorconfig-core-lua]: https://github.com/editorconfig/editorconfig-core-lua

## Supported properties

* `charset`
* `end_of_line`
* `indent_size`
* `indent_style`
* `insert_final_newline`
* `max_line_length`
* `tab_width`
* `trim_trailing_whitespace`

## Contributing

File issues in the [GitHub issue tracker][issues]. Changes can be sent as
[`git-send-email`][git-send-email] patches to
[~gpanders/public-inbox@lists.sr.ht][public-inbox] or as a GitHub pull request.

Lua files should be formatted with [stylua][].

[issues]: https://github.com/gpanders/editorconfig.nvim/issues
[git-send-email]: https://git-send-email.io
[public-inbox]: mailto:~gpanders/public-inbox@lists.sr.ht
[stylua]: https://github.com/johnnymorganz/stylua

## License

[GPLv3][]

[GPLv3]: https://www.gnu.org/licenses/gpl-3.0.html
