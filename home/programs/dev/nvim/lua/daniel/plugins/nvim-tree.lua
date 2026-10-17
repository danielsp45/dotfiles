return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup {
      view = {
        side = "right",
      },
      vim.api.nvim_set_keymap("n", "<S-n>", ":NvimTreeToggle<CR>", {noremap = true})
    }
  end,
}
