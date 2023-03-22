return require('packer').startup(function(use)
    -- Prevent Packer from removing itself
    use 'wbthomason/packer.nvim'

    --Coc Vim
    use {'neoclide/coc.nvim', branch = 'release'}

    -- Gruvbox color scheme
    use 'morhetz/gruvbox'

    --Airline plugin 
    use 'vim-airline/vim-airline'
    use 'vim-airline/vim-airline-themes'

    --Vim wiki
    use 'vimwiki/vimwiki'

    --Plugin to fast scrolling
    use 'psliwka/vim-smoothie'
    
    --Vim commentery
    use 'https://github.com/tpope/vim-commentary.git'

    --fZf pugin
    use 'junegunn/fzf'

    --NerdTree plugin
    use 'https://github.com/preservim/nerdtree.git'

    --Plugin for elixir syntax
    use 'elixir-editors/vim-elixir'

   --Pairs plugin
   use 'https://github.com/jiangmiao/auto-pairs.git'

   --Syntax highlything
   use 'sheerun/vim-polyglot'

   --gitgutter plugin
   use 'https://github.com/airblade/vim-gitgutter.git'

   --ALE plugin 
   use 'dense-analysis/ale'

   --Toggleterm plugin
   use 'https://github.com/akinsho/toggleterm.nvim.git'

   --Fugite vim plugin
   use 'https://github.com/tpope/vim-fugitive.git'

   --Vim icons
   use 'ryanoasis/vim-devicons'

   --Treesitter
   use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})

   -- Vim copilot
   use 'github/copilot.vim'

   -- Astro plugin
   use 'wuelnerdotexe/vim-astro'

end)
