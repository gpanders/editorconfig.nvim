# editorconfig.nvim

EditorConfig plugin for Neovim written in ~~Lua~~ [Fennel][fennel].

editorconfig.nvim is tested against [editorconfig-plugin-tests][].

[fennel]: https://fennel-lang.org
[editorconfig-plugin-tests]: https://github.com/editorconfig/editorconfig-plugin-tests

## Project Status

Neovim 0.9 has EditorConfig integration builtin, so this plugin is no longer
necessary. Bug fixes will continue to be addressed when reported to support
older versions of Neovim, but no further features will be added.

## Supported properties

* `charset`
* `end_of_line`
* `indent_size`
* `indent_style`
* `insert_final_newline`
* `max_line_length`
* `tab_width`
* `trim_trailing_whitespace`

## Adding custom properties

Custom properties can be added through the `properties` table:

```lua
require('editorconfig').properties.foo = function(bufnr, val)
  vim.b[bufnr].foo = val
end
```

## Installation

Install using your favorite package manager, or install manually using Nvim's
builtin package support:

```bash
git clone https://github.com/gpanders/editorconfig.nvim ~/.config/nvim/pack/gpanders/start/editorconfig.nvim
```

This plugin requires no setup and will "just work" when installed.

## FAQ

**Q:** Why use this instead of [editorconfig-vim][]?

**A:** This plugin aims for simplicity and performance: editorconfig-vim contains
over 1000 SLOC, while this plugin has just under 200.

**Q:** Why does it only work for Neovim?

**A:** Vim does not have the same level of support for Lua, and this plugin uses
many Neovim-specific APIs. Vim users should continue to use
[editorconfig-vim][].

[editorconfig-vim]: https://github.com/editorconfig/editorconfig-vim

## Contributing

File issues in the [GitHub issue tracker][issues]. Changes can be sent as
[`git-send-email`][git-send-email] patches to
[~gpanders/public-inbox@lists.sr.ht][public-inbox] or as a GitHub pull request.

[issues]: https://github.com/gpanders/editorconfig.nvim/issues
[git-send-email]: https://git-send-email.io
[public-inbox]: mailto:~gpanders/public-inbox@lists.sr.ht

## License

[GPLv3][]

[GPLv3]: https://www.gnu.org/licenses/gpl-3.0.html

## See Also

* [editorconfig-vim][]
* [vim-sleuth][]

[vim-sleuth]: https://github.com/tpope/vim-sleuth
