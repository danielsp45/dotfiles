return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        -- On the main branch, `setup` no longer takes `ensure_installed`;
        -- parsers are installed explicitly (no-op when already present).
        require("nvim-treesitter").install({
            "c", "cpp", "cmake", "make", "lua", "vim", "vimdoc", "query",
            "elixir", "heex", "javascript", "html",
        })

        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })
    end
}
