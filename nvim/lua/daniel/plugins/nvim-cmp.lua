return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-buffer", -- buffer completion source for nvim-cmp
        "hrsh7th/cmp-path", -- path completion source for nvim-cmp
        "L3MON4D3/LuaSnip", -- snippet engine for nvim-cmp
        "saadparwaiz1/cmp_luasnip", -- LuaSnip completion source for nvim-cmp
        "rafamadriz/friendly-snippets", -- collection of common snippets for LuaSnip
    },
    config = function()
        local cmp = require("cmp")
        local lua_snip = require("luasnip")

        -- Setup nvim-cmp.
        require("luasnip.loaders.from_vscode").lazy_load()
        cmp.setup({
            completion = {
                completeopt = "menu,menuone,preview,noselect"
            },
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end
            },
            mapping = {
                ["<Down>"] = cmp.mapping.select_next_item(),
                ["<Up>"] = cmp.mapping.select_prev_item(),
                ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.close(),
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Insert,
                    select = true,
                }),
            },
            sources = {
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
            },
        })
    end,
}
