" NERDTree
map nt :NERDTreeToggle<cr>
map nf :NERDTreeFind<cr>

" kill the annoyance
nnoremap Q <Nop>

" arrow keys resize pane
nnoremap <A-S-Left> :vertical resize -5<CR>
nnoremap <A-S-Right> :vertical resize +5<CR>
nnoremap <A-S-Up> :resize -5<CR>
nnoremap <A-S-Down> :resize +5<CR>
nnoremap <Left> :vertical resize -1<CR>
nnoremap <Right> :vertical resize +1<CR>
nnoremap <Up> :resize -1<CR>
nnoremap <Down> :resize +1<CR>

" quick add line
nnoremap go o<ESC>
nnoremap gO O<ESC>
" scroll left/right
noremap gh 20zh
noremap gl 20zl

" use alt + left/right keys to switch buffers
noremap <A-Left> :bprev<CR>
noremap <A-Right> :bnext<CR>
" use alt + w to close current buffer
noremap <A-w> :bdelete<CR>
" use alt + W to close all buffers but current one
noremap <A-W> :%bd <BAR> e# <BAR> bd#<CR>

" use alt + up/down keys to move lines
vnoremap <A-Up> dkP1v
vnoremap <A-k> dkP1v
vnoremap <A-Down> dp1v
vnoremap <A-j> dp1v
nnoremap <A-Up> ddkP
nnoremap <A-k> ddkP
nnoremap <A-Down> ddp
nnoremap <A-j> ddp

" leading
let mapleader = ","

noremap <leader>m :call quickui#menu#open()<CR>

" remove search highlight
nnoremap <leader>hs :noh<CR>

" quick save
nnoremap <leader>w :w<CR>

" split panes
nnoremap <leader><Left> :topleft vnew<CR>
nnoremap <leader><Right> :botright vnew<CR>
nnoremap <leader><Up> :topleft new<CR>
nnoremap <leader><Down> :botright new<CR>
nnoremap <leader><Up><Left> :leftabove vnew<CR>
nnoremap <leader><Up><Right> :rightbelow vnew<CR>
nnoremap <leader><Down><Left> :rightbelow new<CR>
nnoremap <leader><Down><Right> :leftabove new<CR>

" navigation / search
nnoremap <C-p> :Files<CR>
nnoremap <C-A-p> :Files!<CR>
nnoremap <leader>/ :BLines<CR>
nnoremap <leader><A-/> :BLines!<CR>
nnoremap <leader>f :Rg<CR>
nnoremap <leader><A-f> :Rg!<CR>
nnoremap <leader>F :RG<CR>
nnoremap <leader><A-F> :RG!<CR>

" vim-visual-increment
vnoremap <C-a> g<C-a>
vnoremap <C-x> g<C-x>
vnoremap g<C-a> <C-a>
vnoremap g<C-x> <C-x>

" vim-sneak
map f <Plug>Sneak_f
map F <Plug>Sneak_F
map t <Plug>Sneak_t
map T <Plug>Sneak_T

" vim-maximizer
nnoremap <leader>z :MaximizerToggle!<CR>

function! GotoWindow(id)
  call win_gotoid(a:id)
  MaximizerToggle
endfunction

" vimspector
nnoremap <leader>dd :call vimspector#Launch()<CR>
nnoremap <leader>dc :call GotoWindow(g:vimspector_session_windows.code)<CR>
nnoremap <leader>dt :call GotoWindow(g:vimspector_session_windows.tagpage)<CR>
nnoremap <leader>dv :call GotoWindow(g:vimspector_session_windows.variables)<CR>
nnoremap <leader>dw :call GotoWindow(g:vimspector_session_windows.watches)<CR>
nnoremap <leader>ds :call GotoWindow(g:vimspector_session_windows.stack_trace)<CR>
nnoremap <leader>do :call GotoWindow(g:vimspector_session_windows.output)<CR>
nnoremap <leader>de :call vimspector#Reset()<CR>

nnoremap <leader>dl <Plug>VimspectorStepInto
nnoremap <leader>dj <Plug>VimspectorStepOver
nnoremap <leader>dk <Plug>VimspectorStepOut
nnoremap <leader>d_ <Plug>VimspectorRestart
nnoremap <leader>d<space> :call vimspector#Continue()<CR>

nnoremap <leader>drc <Plug>VimspectorRunToCursor
nnoremap <leader>dbp <Plug>VimspectorToggleBreakpoint
nnoremap <leader>dcbp <Plug>VimspectorToggleConditionalBreakpoint

" switch.vim and speeddating
" Avoid issues because of us remapping <c-a> and <c-x> below
nnoremap <Plug>SpeedDatingFallbackUp <c-a>
nnoremap <Plug>SpeedDatingFallbackDown <c-x>

" Manually invoke speeddating in case switch didn't work
nnoremap <c-a> :if !switch#Switch() <bar>call speeddating#increment(v:count1) <bar> endif<cr>
nnoremap <c-x> :if !switch#Switch({'reverse': 1}) <bar>call speeddating#increment(-v:count1) <bar> endif<cr>
