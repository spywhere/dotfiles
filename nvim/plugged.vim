if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
else
  let g:init_vim_loaded = 1
endif

call plug#begin('~/.config/nvim/plugged')

" File explorer
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'ryanoasis/vim-devicons'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

" Editing
Plug 'remko/detectindent'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/vim-parenmatch'
Plug 'terryma/vim-multiple-cursors'

Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'wellle/tmux-complete.vim'

" Visualization
Plug 'Yggdroot/indentLine'
Plug 'jeffkreeftmeijer/vim-numbertoggle'

" Navigation
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'christoomey/vim-tmux-navigator'
" Plug 'yuttie/comfortable-motion.vim' " Disabled due to screen lags

" Syntax Highlight
Plug 'lilydjwg/colorizer'
Plug 'sheerun/vim-polyglot'
Plug 'kien/rainbow_parentheses.vim'

" Linting
Plug 'dense-analysis/ale'

" Languages
Plug 'isRuslan/vim-es6'
Plug 'moll/vim-node'
Plug 'othree/yajs.vim'
Plug 'othree/es.next.syntax.vim'

Plug 'kkoomen/vim-doge'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Other
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sensible'
Plug 'wakatime/vim-wakatime'
Plug 'mhinz/vim-startify'

" Color scheme
Plug 'joshdick/onedark.vim'

call plug#end()

if !exists("g:init_vim_loaded")
  finish
endif

syntax on

if (has("autocmd"))
  augroup colorset
    autocmd!
    let s:black = { "gui": "#1C1C1C", "cterm": "234", "cterm16" : "0" }
    autocmd ColorScheme * call onedark#set_highlight("Normal", { "bg": s:black }) " `bg` will not be styled since there is no `bg` setting
  augroup END
endif

colorscheme onedark

" start NERDTree on startup
" autocmd VimEnter * NERDTree
let NERDTreeSortHiddenFirst = 1
let NERDTreeChDirMode = 2
let NERDTreeHijackNetrw = 1
let NERDTreeShowHidden = 1
let NERDTreeMinimalUI = 1
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeIgnore=['\.git$[[dir]]','\.DS_Store$[[file]]']

" NERDTree syntax
let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
let g:NERDTreeHighlightFolders = 1
let g:NERDTreeHighlightFoldersFullName = 1

" NERDCommenter
let g:NERDSpaceDelims = 1

" Rg command tweaks to search only file content
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --smart-case --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%:hidden', '?'),
  \   <bang>0)

" Coc
let g:coc_global_extensions = [
\   'coc-json',
\   'coc-tsserver',
\   'coc-html',
\   'coc-css',
\   'coc-rls',
\   'coc-yaml',
\   'coc-python',
\   'coc-emmet',
\ ]

" Lightline
let g:lightline = {
\   'colorscheme': 'onedark',
\ }

let g:lightline.component = {
\   'filename': '%F',
\ }

let g:lightline.component_expand = {
\   'linter_checking': 'lightline#ale#checking',
\   'linter_infos': 'lightline#ale#infos',
\   'linter_warnings': 'lightline#ale#warnings',
\   'linter_errors': 'lightline#ale#errors',
\   'linter_ok': 'lightline#ale#ok',
\ }

let g:lightline.component_type = {
\   'linter_checking': 'right',
\   'linter_infos': 'right',
\   'linter_warnings': 'warning',
\   'linter_errors': 'error',
\   'linter_ok': 'right',
\ }

let g:lightline.active = {
\   'right': [
\     [
\       'linter_checking',
\       'linter_errors',
\       'linter_warnings',
\       'linter_infos',
\       'linter_ok'
\     ],
\     ['lineinfo'],
\     ['percent'],
\     [
\       'fileformat',
\       'fileencoding',
\       'filetype'
\     ],
\   ]
\ }

" indentLine
let g:indentLine_char = '|'
let g:indentLine_leadingSpaceChar = '·'
let g:indentLine_fileTypeExclude = ['text', 'startify', 'nerdtree']

" startify
let g:startify_files_number = 20
let g:startify_fortune_use_unicode = 1
let g:startify_enable_special = 0
let g:startify_custom_header = 'startify#center(startify#fortune#cowsay())'

" Address issue with NERDTree
"   https://github.com/Yggdroot/indentLine/issues/152
function EnableLeadingSpace()
  if bufname() =~ 'NERD_tree'
    call DisableSpaceVisual()
    return
  elseif &filetype == 'startify'
    call DisableSpaceVisual()
    return
  endif

  :LeadingSpaceEnable
  :set list
endfunction

function DisableSpaceVisual()
  :LeadingSpaceDisable
  :set nolist
endfunction

autocmd InsertEnter * call DisableSpaceVisual()
autocmd InsertLeave * call EnableLeadingSpace()
autocmd BufEnter * call EnableLeadingSpace()
