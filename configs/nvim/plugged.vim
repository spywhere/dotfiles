if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | q | source $MYVIMRC
  let g:first_install = 1
else
  let g:init_vim_loaded = 1
endif

if !has('nvim-0.5')
  " Use treesitter instead
  let g:polyglot_disbled = ['javascript']
endif

call plug#begin('~/.config/nvim/plugged')

" File explorer
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'airblade/vim-rooter'

" Editing
Plug 'remko/detectindent', { 'on': 'DetectIndent' }
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/vim-parenmatch'
Plug 'christoomey/vim-sort-motion'
Plug 'AndrewRadev/switch.vim'
Plug 'tpope/vim-speeddating'

" Autocompletion
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'wellle/tmux-complete.vim'

" Experimental: A replacement for coc.nvim
" Currently need to manually install a language server as opposed to coc.nvim
"   where you can have it auto install for you with less hassle
" Plug 'neovim/nvim-lspconfig'
" Plug 'nvim-lua/completion-nvim'

" Debugging
Plug 'puremourning/vimspector'

" Window Manager
Plug 'szw/vim-maximizer'

" Visualization
Plug 'Yggdroot/indentLine'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'AndrewRadev/linediff.vim'

" Navigation
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Experimental: A replacement for fzf
" Currently does not perform well compared to fzf itself
" Plug 'nvim-lua/popup.nvim'
" Plug 'nvim-lua/plenary.nvim'
" Plug 'nvim-lua/telescope.nvim'

Plug 'tpope/vim-rsi'
Plug 'wellle/targets.vim'
Plug 'christoomey/vim-tmux-navigator', { 'on': [] }
" Plug 'psliwka/vim-smoothie' # smooth scrolling
Plug 'justinmk/vim-sneak'

" Syntax Highlight
Plug 'norcalli/nvim-colorizer.lua'
Plug 'sheerun/vim-polyglot'
Plug 'kien/rainbow_parentheses.vim'
if has('nvim-0.5')
  Plug 'nvim-treesitter/nvim-treesitter', { 'do': 'TSUpdate' } " Experimental until nvim-0.5
endif

" Linting
Plug 'dense-analysis/ale'

" Languages
Plug 'moll/vim-node'
Plug 'othree/yajs.vim'
Plug 'othree/es.next.syntax.vim'

" Documentation
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() }, 'on': 'DogeGenerate' }

" Git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'rhysd/git-messenger.vim'

" Appearances
Plug 'itchyny/lightline.vim'
" Plug 'mengelbrecht/lightline-bufferline'
Plug 'spywhere/lightline-bufferline', { 'branch': 'lua-nvim' } " patched for lua on nvim
Plug 'maximbaz/lightline-ale'
Plug 'mhinz/vim-startify'
Plug 'skywind3000/vim-quickui'

" Standard
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sensible'

" Tracking
Plug 'wakatime/vim-wakatime'

" Session management
Plug 'tpope/vim-obsession'
Plug 'djoshea/vim-autoread'

" Color scheme
" Plug 'gruvbox-community/gruvbox'
" Plug 'joshdick/onedark.vim'
Plug 'arcticicestudio/nord-vim'

call plug#end()

if !exists('g:init_vim_loaded')
  finish
endif

" Automatically install missing plugins on startup
autocmd VimEnter *
\  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
\  |   PlugInstall --sync | q
\  | endif

syntax on

augroup lazyload_plugins
  autocmd!
  autocmd CursorHold * call plug#load('vim-tmux-navigator') | autocmd! lazyload_plugins
augroup END

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 300})
augroup END

" Running some patches
source ~/.config/nvim/monkey-patch.vim

colorscheme nord

" colorizer
lua require'colorizer'.setup()

" treesitter
if has('nvim-0.5')
  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    ensure_installed = 'all',
    highlight = {
      enable = true
    }
  }
EOF
endif

" Try to startup autocommand manually on first install completion
if exists('g:first_install')
  call ColorSetup()
  Startify
endif
