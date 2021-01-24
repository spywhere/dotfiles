" be IMproved!
set nocompatible

set scrolloff=10
set sidescrolloff=10
set number
set relativenumber
set hidden
set nowrap
" Use lightline, so no need for mode
set noshowmode
set showmatch
" Yank into system clipboard as well
set clipboard=unnamed
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=auto:1-3

set wildignore=*.o,*~,*.pyc

" File format detection
set ffs=unix,dos,mac

" Always show status line and tab line
set laststatus=2
set cmdheight=1

" Print margin at 79 chars
set colorcolumn=79

" Split the window to the right / below first
set splitbelow splitright

set nobackup
set nowritebackup
set noswapfile

set noerrorbells
set visualbell
set timeoutlen=500
set updatetime=300
set lazyredraw

set ignorecase
set smartcase
set hlsearch

set expandtab
set smarttab
set smartindent
set shiftwidth=2
set tabstop=2

" Whitespace visual chars
set listchars=tab:→\ ,trail:·,nbsp:·

set autoread

" disable netrw in favor of NERDTree
let loaded_netrwPlugin = 1

let g:vimsyn_embed = 'l' " Allow Lua highlighting in vimscript
