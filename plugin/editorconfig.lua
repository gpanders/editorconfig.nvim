-- Disable builtin EditorConfig when using this plugin
vim.g.editorconfig_enable = false

-- Once Neovim 0.9 is released, uncomment this
--[[
if vim.fn.has('nvim-0.9') then
    vim.notify_once(
        "editorconfig.nvim: This plugin has been upstreamed to Neovim and is no longer necessary. Consider uninstalling.",
        vim.log.levels.INFO,
        { title = "editorconfig.nvim" }
    )
end
]]
