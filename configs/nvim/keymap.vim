" NERDTree
map nt :NERDTreeToggle<cr>
map nf :NERDTreeFind<cr>

" kill the annoyance
nnoremap Q <Nop>

" arrow keys resize pane
nnoremap <A-Left> :vertical resize -5<CR>
nnoremap <A-Right> :vertical resize +5<CR>
nnoremap <Left> :vertical resize -1<CR>
nnoremap <Right> :vertical resize +1<CR>
nnoremap <Up> :resize -1<CR>
nnoremap <Down> :resize +1<CR>

" shortcut for enter command mode
nnoremap ;; :

" quick add line
nnoremap go o<ESC>
nnoremap gO O<ESC>

" use alt + arrow keys to move lines
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

" cmus controls
nnoremap <leader>pp :silent !(echo "pause\nclose"; sleep 0.05) \| nc 127.0.0.1 6600<CR>
nnoremap <leader>pn :silent !(echo "next\nclose"; sleep 0.05) \| nc 127.0.0.1 6600<CR>
nnoremap <leader>pr :silent !(echo "previous\nclose"; sleep 0.05) \| nc 127.0.0.1 6600<CR>

" ctrl+p
nnoremap <C-p> :Files<CR>
nnoremap <leader>f :Rg<CR>
