let g:nvim_tree_icons = {
\   'default': ' '
\ }
let g:nvim_tree_ignore = ['.git', '.DS_Store']
let g:nvim_tree_follow = 1

" show cursorline when browsing in the tree explorer
autocmd BufEnter,FileType NvimTree let &cursorline=1
