return {
    "luisiacc/gruvbox-baby",
    config = function()
        vim.opt.pumblend = 0
        vim.g.gruvbox_baby_transparent_mode = true -- Enable transparent mode
        vim.cmd[[colorscheme gruvbox-baby]]
    end,
}
