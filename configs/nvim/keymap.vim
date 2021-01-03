" NERDTree
map nt :NvimTreeToggle<cr>
map nf :NvimTreeFindFile<cr>

" kill the annoyance
nnoremap Q <Nop>

" arrow keys resize pane
nnoremap <A-S-Left> :vertical resize -5<cr>
nnoremap <A-S-Right> :vertical resize +5<cr>
nnoremap <A-S-Up> :resize -5<cr>
nnoremap <A-S-Down> :resize +5<cr>
nnoremap <Left> :vertical resize -1<cr>
nnoremap <Right> :vertical resize +1<cr>
nnoremap <Up> :resize -1<cr>
nnoremap <Down> :resize +1<cr>

" quick add line
nnoremap go o<ESC>
nnoremap gO O<ESC>
" scroll left/right
noremap gh 20zh
noremap gl 20zl

" use alt + left/right keys to switch buffers
noremap <A-Left> :bprev<cr>
noremap <A-Right> :bnext<cr>
" use alt + w to close current buffer
noremap <A-w> :bdelete<cr>
" use alt + W to close all buffers but current one
noremap <A-W> :%bd <BAR> e# <BAR> bd#<cr>

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

noremap <leader>m :call quickui#menu#open()<cr>

" remove search highlight
nnoremap <leader>hs :noh<cr>

" quick save
nnoremap <leader>w :w<cr>

" split panes
nnoremap <leader><Left> :topleft vnew<cr>
nnoremap <leader><Right> :botright vnew<cr>
nnoremap <leader><Up> :topleft new<cr>
nnoremap <leader><Down> :botright new<cr>
nnoremap <leader><Up><Left> :leftabove vnew<cr>
nnoremap <leader><Up><Right> :rightbelow vnew<cr>
nnoremap <leader><Down><Left> :rightbelow new<cr>
nnoremap <leader><Down><Right> :leftabove new<cr>

" navigation / search
nnoremap <C-p> :Files<cr>
nnoremap <C-A-p> :Files!<cr>
nnoremap <leader>/ :BLines<cr>
nnoremap <leader><A-/> :BLines!<cr>
nnoremap <leader>f :Rg<cr>
nnoremap <leader><A-f> :Rg!<cr>
nnoremap <leader>F :RG<cr>
nnoremap <leader><A-F> :RG!<cr>

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
nnoremap <leader>z :MaximizerToggle!<cr>

function! GotoWindow(id)
  call win_gotoid(a:id)
  MaximizerToggle
endfunction

" vimspector
nnoremap <leader>dd :call vimspector#Launch()<cr>
nnoremap <leader>dc :call GotoWindow(g:vimspector_session_windows.code)<cr>
nnoremap <leader>dt :call GotoWindow(g:vimspector_session_windows.tagpage)<cr>
nnoremap <leader>dv :call GotoWindow(g:vimspector_session_windows.variables)<cr>
nnoremap <leader>dw :call GotoWindow(g:vimspector_session_windows.watches)<cr>
nnoremap <leader>ds :call GotoWindow(g:vimspector_session_windows.stack_trace)<cr>
nnoremap <leader>do :call GotoWindow(g:vimspector_session_windows.output)<cr>
nnoremap <leader>de :call vimspector#Reset()<cr>

nnoremap <leader>dl <Plug>VimspectorStepInto
nnoremap <leader>dj <Plug>VimspectorStepOver
nnoremap <leader>dk <Plug>VimspectorStepOut
nnoremap <leader>d_ <Plug>VimspectorRestart
nnoremap <leader>d<space> :call vimspector#Continue()<cr>

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
