-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- local cowboy = require('cowboy')
-- cowboy.cowboy()

lvim.plugins = {
  { "luisiacc/gruvbox-baby" },
  { "psliwka/vim-smoothie" },
  { "github/copilot.vim" },
  { 'gleam-lang/gleam.vim' },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        background_colour = "#000000",
      })
    end,
  },
  { "wakatime/vim-wakatime" },
  -- { dir = "~/projects/dot.nvim"},
}

vim.notify = require("notify")

lvim.builtin.nvimtree.defaults = {
  view = {
    side = "right"
  }
}
lvim.keys.normal_mode["<S-n>"] = ":NvimTreeToggle<CR>"

-- Turn relative numbers one
vim.opt.relativenumber = true

-- Set colorscheme
lvim.colorscheme = "gruvbox-baby"


-- Set transparent_window
lvim.transparent_window = true

vim.g.copilot_assume_mapped = true

vim.opt.termguicolors = true

local cmp_nvim_lsp = require "cmp_nvim_lsp"
require("lspconfig").clangd.setup {
  on_attach = on_attach,
  capabilities = cmp_nvim_lsp.default_capabilities(),
  cmd = {
    "clangd",
    "--offset-encoding=utf-16",
  },
}


lvim.format_on_save.enabled = true

lvim.builtin.nvimtree.setup.view.side = "right"
