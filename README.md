# editorconfig.nvim

EditorConfig plugin for Neovim written in ~~Lua~~ [Fennel][fennel].

editorconfig.nvim is tested against [editorconfig-plugin-tests][].

This plugin is considered complete: bugs will continue to be fixed if and when
they're found, but no new features will be added (except to stay up-to-date with
any changes to the EditorConfig specification).

[fennel]: https://fennel-lang.org
[editorconfig-plugin-tests]: https://github.com/editorconfig/editorconfig-plugin-tests

## Supported properties

* `charset`
* `end_of_line`
* `indent_size`
* `indent_style`
* `insert_final_newline`
* `max_line_length`
* `tab_width`
* `trim_trailing_whitespace`

## FAQ

**Q:** Why use this instead of [editorconfig-vim][]?

**A:** This plugin aims for simplicity and performance: editorconfig-vim contains
over 1000 SLOC, while this plugin has just under 200.

Additionally, while performance for an EditorConfig plugin is certainly not the
most important thing in the world, it still matters, particularly since it is
going to run each time you open a new buffer. This plugin is not only smaller
than editorconfig-vim, but is written in Lua, which is demonstrably faster than
Vimscript.

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
