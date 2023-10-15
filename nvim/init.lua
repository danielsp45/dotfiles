require('plugins')
require('coc')
require('treesitter')

-- Clipboard
vim.api.nvim_command("set clipboard=unnamedplus")

--Keybindings
vim.api.nvim_set_keymap("n", "<S-n>", ":NERDTreeToggle<CR>", {noremap = true})
vim.api.nvim_set_keymap("n", "<S-f>", ":FZF<CR>", {noremap = true})
vim.api.nvim_set_keymap("n", "<S-t>", ":ToggleTerm<CR>", {noremap = true})

--Vim icons
vim.api.nvim_command("set encoding=UTF-8")

--Turns on the line number
vim.api.nvim_command("set number")

--Turns off word highlighting after word search
vim.api.nvim_command("set nohlsearch")

--Turns on the relative numbers
vim.api.nvim_command("set relativenumber")

--Sets tab to 4 spaces
vim.api.nvim_command("set tabstop=4")
vim.api.nvim_command("set shiftwidth=4")
vim.api.nvim_command("set softtabstop=4")
vim.api.nvim_command("set expandtab")

--Turns on the mouse
vim.api.nvim_command("set mouse=a")

--Airline configs
vim.cmd("let g:airline_detect_paste=1")
vim.cmd("let g:airline_left_sep = ''")
vim.cmd("let g:airline_powerline_fonts = 1")
vim.cmd("let g:airline_right_sep = ''")
vim.cmd("let g:airline_theme = 'gruvbox'")

--NerdTree config
vim.cmd("let g:NERDTreeWinPos = 'right'")

--Autocomplit coc vim configs
-- vim.api.nvim_set_keymap("i", "<CR>", "<cmd>lua require'coc.pum'.visible() require'coc.pum'.confirm() or '<CR>'<CR>", {noremap = true})

--Dashboard configs
vim.g.dashboard_default_executive = 'fzf'

--Gruvbox configs
vim.cmd("colorscheme gruvbox")
vim.cmd("syntax on")
vim.cmd("set background=dark")
vim.cmd("let g:gruvbox_contrast_dark = 'medium'")

if os.getenv("TMUX") == nil then
  if vim.fn.has("nvim") == 1 then
    vim.cmd("let $NVIM_TUI_ENABLE_TRUE_COLOR=1")
  end
  if vim.fn.has("termguicolors") == 1 then
    vim.cmd("set termguicolors")
  end
end


--Automatically compile packer when changing this file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
