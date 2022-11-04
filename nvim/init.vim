source $HOME/.config/nvim/vim-plug/plugins.vim
source $HOME/.config/nvim/themes/airline.vim
source $HOME/.config/nvim/plug-config/coc.vim
"----------keybindings-----------

"NERDTree configs
nmap <S-n> :NERDTreeToggle<CR>
nmap <S-f> :FZF<CR>
nmap <S-t> :ToggleTerm<CR>

"Clipboard
set clipboard=unnamedplus

"Vim icons
set encoding=UTF-8

"Turns on the line numbers
set number

"Turns off word highlighting after a word search
set nohlsearch

"Turns on the relative numbers
set relativenumber

"Sets Tab to 4 spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

"Turns on mouse
set mouse=a

"Airline configs
let g:airline_detect_paste=1
let g:airline_left_sep = ''
let g:airline_powerline_fonts = 1
let g:airline_right_sep = ''

" NerdTree config
let g:NERDTreeWinPos = "right"

"Autocompletion deoplete configs
set encoding=utf-8
set pyxversion=3

"Dashboard configs
let g:dashboard_default_executive ='fzf'

"Gruvbox configs
syntax on
set background=dark "Setting dark mode
let g:gruvbox_contrast_dark = 'medium'
"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif

" Enable syntax highlighting
syntax on

" Enables filetype detection, loads ftplugin, and loads indent
" (Not necessary on nvim and may not be necessary on vim 8.2+)
filetype plugin indent on

"ACTIVE COLOR SCHEME
filetype plugin on
syntax on

colorscheme gruvbox
"Turns transparecy mode on in neovim
hi Normal guibg=NONE ctermbg=NONE
