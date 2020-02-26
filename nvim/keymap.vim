" NERDTree
map nt :NERDTreeToggle<cr>
map nf :NERDTreeFind<cr>

" arrow keys resize pane
nnoremap <A-Left> :vertical resize -5<CR>
nnoremap <A-Right> :vertical resize +5<CR>
nnoremap <A-Up> :resize -5<CR>
nnoremap <A-Down> :resize +5<CR>
nnoremap <Left> :vertical resize -1<CR>
nnoremap <Right> :vertical resize +1<CR>
nnoremap <Up> :resize -1<CR>
nnoremap <Down> :resize +1<CR>

" use alt + arrow keys to move lines
vnoremap <A-Up> dkP1v
vnoremap <A-k> dkP1v
vnoremap <A-Down> dp1v
vnoremap <A-j> dp1v
nnoremap <A-Up> ddkP
nnoremap <A-k> ddkP
nnoremap <A-Down> ddp
nnoremap <A-j> ddp

" Leading
let mapleader = ","

noremap <leader>h 20zh
noremap <leader>l 20zl

" remove search highlight
nnoremap <leader>hs :noh<CR>

" split panes
nnoremap <leader><Left> :topleft vnew<CR>
nnoremap <leader><Right> :botright vnew<CR>
nnoremap <leader><Up> :topleft new<CR>
nnoremap <leader><Down> :botright new<CR>
nnoremap <leader><Up><Left> :leftabove vnew<CR>
nnoremap <leader><Up><Right> :rightbelow vnew<CR>
nnoremap <leader><Down><Left> :rightbelow new<CR>
nnoremap <leader><Down><Right> :leftabove new<CR>

" cmus controls
nnoremap <leader>pp :silent !cmus-remote -u<CR>
nnoremap <leader>pn :silent !cmus-remote -n<CR>
nnoremap <leader>pr :silent !cmus-remote -r<CR>

" ctrl+p
nnoremap <C-p> :Files<CR>
nnoremap <leader>f :Rg<CR>
