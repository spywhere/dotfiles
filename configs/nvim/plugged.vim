if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
else
  let g:init_vim_loaded = 1
endif

call plug#begin('~/.config/nvim/plugged')

" File explorer
Plug 'preservim/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'ryanoasis/vim-devicons'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

" Editing
Plug 'remko/detectindent', { 'on': 'DetectIndent' }
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/vim-parenmatch'
Plug 'terryma/vim-multiple-cursors'

Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'wellle/tmux-complete.vim'

" Visualization
Plug 'Yggdroot/indentLine'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'AndrewRadev/linediff.vim'
Plug 'machakann/vim-highlightedyank'

" Navigation
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-rsi'
Plug 'christoomey/vim-tmux-navigator', { 'on': [] }
" Plug 'yuttie/comfortable-motion.vim' " Disabled due to screen lags
Plug 'easymotion/vim-easymotion', { 'on': [] }

" Syntax Highlight
Plug 'norcalli/nvim-colorizer.lua'
Plug 'sheerun/vim-polyglot'
Plug 'kien/rainbow_parentheses.vim'

" Linting
Plug 'dense-analysis/ale'

" Languages
Plug 'isRuslan/vim-es6'
Plug 'moll/vim-node'
Plug 'othree/yajs.vim'
Plug 'othree/es.next.syntax.vim'

Plug 'kkoomen/vim-doge', { 'on': 'DogeGenerate' }

" Git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Appearances
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
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
Plug 'joshdick/onedark.vim'

call plug#end()

if !exists("g:init_vim_loaded")
  finish
endif

syntax on

if (has("autocmd"))
  augroup lazyload_plugins
    autocmd!
    autocmd CursorHold * call plug#load('vim-easymotion', 'vim-tmux-navigator') | autocmd! lazyload_plugins
  augroup END

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
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%', '?'),
  \   <bang>0)

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --hidden --smart-case --no-heading --color=always -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec, 'right:50%', '?'), a:fullscreen)
endfunction

command! -bang -nargs=* RG call RipgrepFzf(<q-args>, <bang>0)

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

" ALE
" Only run on open or save file
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0

" QuickUI
let g:quickui_show_tip = 1
let g:quickui_border_style = 2
let g:quickui_color_scheme = 'papercol dark'

call quickui#menu#reset()

call quickui#menu#install('&File', [
\   ["&New Buffer\t:enew", 'enew', 'Create a new empty buffer in current window'],
\   ["New &Vertical Buffer\t:vnew", 'vnew', 'Create a new empty buffer in a new vertical split'],
\   ['--'],
\   ["&Save\t,w", 'write', 'Save changes on current buffer'],
\   ["Save &All\t:wall", 'wall', 'Save changes on all buffers'],
\   ['--'],
\   ["&Reload %{&modified?'Unsaved ':''}Buffer\t:edit!", 'edit!', 'Reload current buffer'],
\   ["Close &Window\t<C-w>q", 'close', 'Close current window'],
\   ["&Close %{&modified?'Unsaved ':''}Buffer\t<A-w>", 'bdelete!', 'Close current buffer'],
\   ["Close &Others\t<A-w>", '%bd | e# | bd#', 'Close all buffers including no name except current one'],
\ ])
call quickui#menu#install('&Edit', [
\   ["&Undo\tu", 'undo', 'Undo the latest change'],
\   ["&Redo\t<C-y>", 'redo', 'Redo the latest change'],
\   ['--'],
\   ["&Cut\td", 'delete', 'Cut the current line into the yank register'],
\   ["Cop&y\ty", 'yank', 'Yank the current line into the yank register'],
\   ["&Paste\tp", 'put', 'Put the content in yank register after the cursor'],
\   ['--'],
\   ["F&ind\t:<leader>/", 'BLines', 'Initiate a search mode'],
\   ["&Find in Files\t:<leader>f", 'Rg', 'Search for pattern across the project'],
\   ['--'],
\   ["Toggle &Line Comment\t<leader>c<space>", 'call NERDComment("n", "Toggle")', 'Toggle line comments'],
\   ["Insert &Block Comment\t<leader>cs>", 'call NERDComment("n", "Sexy")', 'Insert block comments'],
\ ])
call quickui#menu#install('&View', [
\   [" Command &Palette\t:Commands", 'Commands', 'Open a command list'],
\   ['--'],
\   ["%{exists('w:indentLine_indentLineId') && ! empty(w:indentLine_indentLineId)?'✓':' '}Render &Indent Guides\t:IndentLinesToggle", 'IndentLinesToggle', 'Toggle indentation guide lines'],
\   ["%{&list?'✓':' '}&Render Whitespace\t:set invlist", 'set invlist | LeadingSpaceToggle', 'Toggle render of whitespace characters'],
\   ["%{&wrap?'✓':' '}&Word Wrap\t:set invwrap", 'set invwrap', 'Toggle a word wrap'],
\   ['--'],
\   ["%{&spell?'✓':' '}&Spell Check\t:set invspell", 'set invspell', 'Toggle a spell check'],
\   ["%{&cursorline?'✓':' '}Cursor &Line\t:set invcursorline", 'set invcursorline', 'Toggle render of current cursor line'],
\   ["%{&cursorcolumn?'✓':' '}Cursor &Column\t:set invcursorcolumn", 'set invcursorcolumn', 'Toggle render of current cursor column'],
\ ])

" Lightline-bufferline
let g:lightline#bufferline#enable_devicons = 1
let g:lightline#bufferline#min_buffer_count = 2

" Lightline
let g:lightline = {
\   'colorscheme': 'onedark',
\ }

let g:lightline.tabline = {
\   'left': [
\     ['buffers']
\   ],
\   'right': [
\     ['close']
\   ],
\ }

let g:lightline.component_expand = {
\   'linter_checking': 'lightline#ale#checking',
\   'linter_infos': 'lightline#ale#infos',
\   'linter_warnings': 'lightline#ale#warnings',
\   'linter_errors': 'lightline#ale#errors',
\   'linter_ok': 'lightline#ale#ok',
\   'buffers': 'lightline#bufferline#buffers',
\ }

let g:lightline.component_type = {
\   'linter_checking': 'right',
\   'linter_infos': 'right',
\   'linter_warnings': 'warning',
\   'linter_errors': 'error',
\   'linter_ok': 'right',
\   'buffers': 'tabsel',
\ }

function! LightlineMode()
  return &ft !=? 'nerdtree' ? lightline#mode() : ''
endfunction

function! LightlineBranch()
  return &ft !=? 'nerdtree' ? FugitiveHead() : ''
endfunction

function! LightlineReadonly()
  return &ft !=? 'nerdtree' && &readonly ? 'RO' : ''
endfunction

function! LightlineModified()
  return &ft !=? 'nerdtree' && &modified ? '+' : ''
endfunction

function! LightlineRelativePath()
  return &ft !=? 'nerdtree' ? expand('%:f') != '' ? expand('%:f') : '[no name]' : 'NERD'
endfunction

function! LightlineLineInfo()
  return &ft !=? 'nerdtree' ? line('.') . ':' . col('.') : ''
endfunction

function! LightlinePercent()
  return &ft !=? 'nerdtree' ? line('.') * 100 / line('$') . '%' : ''
endfunction

function! LightlineFileFormat()
  return &ft !=? 'nerdtree' ? &ff : ''
endfunction

function! LightlineFileEncoding()
  return &ft !=? 'nerdtree' ? &enc : ''
endfunction

function! LightlineFileType()
  return &ft !=? 'nerdtree' ? &filetype : ''
endfunction

let g:lightline.component_function = {
\   'obsession': 'ObsessionStatus',
\   'gitbranch': 'LightlineBranch',
\   'mode': 'LightlineMode',
\   'readonly': 'LightlineReadonly',
\   'modified': 'LightlineModified',
\   'relativepath': 'LightlineRelativePath',
\   'lineinfo': 'LightlineLineInfo',
\   'percent': 'LightlinePercent',
\   'fileformat': 'LightlineFileFormat',
\   'fileencoding': 'LightlineFileEncoding',
\   'filetype': 'LightlineFileType'
\ }

let g:lightline.inactive = {
\   'left': [
\     ['relativepath']
\   ],
\   'right': [
\     ['lineinfo'],
\     ['percent']
\   ]
\ }

let g:lightline.active = {
\   'left': [
\     ['mode', 'paste'],
\     ['gitbranch', 'readonly', 'relativepath', 'modified']
\   ],
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
\     ['obsession'],
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

" colorizer
lua require'colorizer'.setup()
" lua require'colorizer'.setup {
" \   'css';
" \   'html';
" \ }

