" NERDTree
map nt :NERDTreeToggle<cr>
map nf :NERDTreeFind<cr>

" arrow keys resize pane
inoremap <Left> <C-o>:vertical resize -5<CR>
inoremap <Right> <C-o>:vertical resize +5<CR>
inoremap <Up> <C-o>:resize -5<CR>
inoremap <Down> <C-o>:resize +5<CR>
nnoremap <Left> :vertical resize -1<CR>
nnoremap <Right> :vertical resize +1<CR>
nnoremap <Up> :resize -1<CR>
nnoremap <Down> :resize +1<CR>

" Leading
let mapleader = ","

noremap <leader>h 20zh
noremap <leader>l 20zl

nnoremap <leader>hs :noh<CR>

" cmus controls
nnoremap <leader>pp :silent !cmus-remote -u<CR>
nnoremap <leader>pn :silent !cmus-remote -n<CR>
nnoremap <leader>pr :silent !cmus-remote -r<CR>

" ctrl+p
nnoremap <C-p> :Files<CR>
nnoremap <leader>f :Rg<CR>
