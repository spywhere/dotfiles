set nocompatible

if (has("termguicolors"))
  set termguicolors
endif

set scrolloff=10
set number
set relativenumber
set hidden
set nowrap
set noshowmode
set showmatch
set clipboard=unnamed

set wildignore=*.o,*~,*.pyc

" File format detection
set ffs=unix,dos,mac

" Always show status line
set laststatus=2
set cmdheight=1

" Print margin at 79 chars
set colorcolumn=79

" set nowb
set nobackup
set nowritebackup
set noswapfile

set noerrorbells
set visualbell
set tm=500
set updatetime=300

set ignorecase
set smartcase
set hlsearch

set expandtab
set smarttab
set smartindent
set shiftwidth=2
set tabstop=2

set autoread
set guifont=JetbrainsMonoNerdFontMono:h12

" disable netrw in favor of NERDTree
let loaded_netrwPlugin = 1

source ~/.config/nvim/plugged.vim
if exists("g:init_vim_loaded")
  source ~/.config/nvim/keymap.vim
  source ~/.config/nvim/coc.vim
endif
