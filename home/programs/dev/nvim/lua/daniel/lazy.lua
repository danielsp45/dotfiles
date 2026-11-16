local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = "\\" -- Same for `maplocalleader`

require("lazy").setup({
    spec = {
        {import = "daniel.plugins"},
        {import = "daniel.plugins.lsp"},
    },

    -- plugins with `dev = true` load from ~/Projects when checked out there,
    -- and are cloned from GitHub otherwise
    dev = {
        path = "~/Projects",
        fallback = true,
    },

    -- ui config
    ui = {
        wrap = true, -- wrap the lines in the ui
        -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
        border = "single",
        size = {
            width = 0.8,
            height = 0.8,
        },
    },
})
