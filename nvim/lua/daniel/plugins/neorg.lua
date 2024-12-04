return {
    "nvim-neorg/neorg",
    depends = { "nvim-lua/plenary.nvim" },
    lazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
    config = function()
        require("neorg").setup({
            load = {
                ["core.defaults"] = {},
                ["core.concealer"] = {}, -- We added this line!
                ["core.dirman"] = {
                    config = {
                        workspaces = {
                            notes = "~/notes",
                        }
                    }
                }
            }
        })
    end,
}
