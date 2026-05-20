return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup({
            ensure_installed = {
                "c", "lua", "vim", "vimdoc", "query",
                "elixir", "heex", "javascript", "html",
            },
        })
    end
}
