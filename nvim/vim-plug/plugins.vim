call plug#begin('~/.config/nvim/autoload/plugged')

"Airline plugin 
Plug 'https://github.com/vim-airline/vim-airline.git'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

"Plugin to fast scrolling
Plug 'psliwka/vim-smoothie'

"Syntastic Vim plugin 
Plug 'https://github.com/vim-syntastic/syntastic.git'

"Code formater
Plug 'mhinz/vim-mix-format'

"Vim commentery
Plug 'https://github.com/tpope/vim-commentary.git'

"Pairs plugin
Plug 'https://github.com/jiangmiao/auto-pairs.git'

"Gruvbox theme 
Plug 'morhetz/gruvbox'

"NerdTree plugin
Plug 'https://github.com/preservim/nerdtree.git'

"VimSense plugin to show on discord what I'm doing
Plug 'https://github.com/vimsence/vimsence.git'

"ALE plugin 
Plug 'https://github.com/dense-analysis/ale.git'

"Toggleterm plugin
Plug 'https://github.com/akinsho/toggleterm.nvim.git'

"Fugite vim plugin
Plug 'https://github.com/tpope/vim-fugitive.git'

"gitgutter plugin
Plug 'https://github.com/airblade/vim-gitgutter.git'

"Vim icons
Plug 'ryanoasis/vim-devicons'

"HTML plugin
Plug 'maxmellon/vim-jsx-pretty' 
Plug 'Yggdroot/indentLine'

"Elixir plugin
Plug 'elixir-editors/vim-elixir'

"Intellisense plugin
Plug 'neoclide/coc.nvim', {'branch': 'release'}
""For elixir development
"Plug 'amiralies/coc-elixir', {'do': 'yarn install && yarn prepack'}

"fZf pugin
Plug 'junegunn/fzf'

"Dashboard for vim
Plug 'glepnir/dashboard-nvim'

"Syntax highlything
Plug 'sheerun/vim-polyglot'

"Plugin for elixir syntax
Plug 'elixir-editors/vim-elixir'

"Github copilot
Plug 'github/copilot.vim'

"Glang formater
Plug 'rhysd/vim-clang-format'

"tmux navigator plugin
" Plugin 'christoomey/vim-tmux-navigator'

"Noice vim
Plug 'folke/noice.nvim'
Plug 'MunifTanjim/nui.nvim'
"deoplete autocompletion plugin
" if has('nvim')
"   Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" else
"   Plug 'Shougo/deoplete.nvim'
"   Plug 'roxma/nvim-yarp'
"   Plug 'roxma/vim-hug-neovim-rpc'
" endif
" let g:deoplete#enable_at_startup = 1

" if has('win32') || has('win64')
"   Plug 'tbodt/deoplete-tabnine', { 'do': 'powershell.exe .\install.ps1' }
" else
"   Plug 'tbodt/deoplete-tabnine', { 'do': './install.sh' }
" endif


call plug#end()
