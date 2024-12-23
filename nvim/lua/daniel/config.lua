-- Vim options
vim.opt.relativenumber = true
vim.opt.termguicolors = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
vim.opt.background = "dark" -- colorschemes that can be light or dark will be made dark
vim.opt.signcolumn = "yes" -- show sign column so that text doesn't shift
-- make popup menu transparent 
-- value range [0,100]
vim.opt.pumblend = 0

-- Clipboard
vim.api.nvim_command("set clipboard=unnamedplus")

vim.api.nvim_command("set tabstop=4") -- Sets tab to 4 spaces
vim.api.nvim_command("set shiftwidth=4") -- Sets shiftwidth to 4 spaces
vim.api.nvim_command("set softtabstop=4") -- Sets softtabstop to 4 spaces

vim.lsp.handlers["textDocument/hover"] =
vim.lsp.with(
    vim.lsp.handlers.hover,
    {
        border = "single",
    }
)

vim.lsp.handlers["textDocument/signatureHelp"] =
vim.lsp.with(
    vim.lsp.handlers.signature_help,
    {
        border = "single",
    }
)

vim.api.nvim_create_user_command("DiagnosticToggle", function()
    local config = vim.diagnostic.config
    local vt = config().virtual_text
    config {
        virtual_text = not vt,
        underline = not vt,
        signs = not vt,
    }
end, { desc = "toggle diagnostic" })
