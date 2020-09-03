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

noremap <leader>h 20zh
noremap <leader>l 20zl

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
