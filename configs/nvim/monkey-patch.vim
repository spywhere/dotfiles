" Overriding background color to be more darker, hide split column
function! ColorSetup()
  exec "hi Normal guibg=#1C1C1C ctermbg=234"
  exec "hi SignColumn guibg=#1C1C1C ctermbg=234"
  exec "hi VertSplit guifg=bg ctermfg=bg guibg=#1C1C1C ctermbg=234"
endfunction

augroup colorset
  autocmd!
  autocmd ColorScheme * call ColorSetup()
augroup END

" Overriding right component to show some colors
let s:palette = g:lightline#colorscheme#nord#palette
let s:palette.normal.right = [
\   [
\     "#3B4252",
\     "#88C0D0"
\   ],
\   [
\     "#E5E9F0",
\     "#3B4252"
\   ]
\ ]
let g:lightline#colorscheme#n0rd#palette = lightline#colorscheme#fill(s:palette)

