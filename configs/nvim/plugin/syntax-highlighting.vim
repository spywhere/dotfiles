" vim-markdown
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0

if (has("termguicolors"))
  set termguicolors
endif
" colorizer
lua require'colorizer'.setup()

" treesitter
if has('nvim-0.5')
  lua <<EOF
  require'nvim-treesitter.configs'.setup {
    ensure_installed = 'all',
    highlight = {
      enable = true
    }
  }
EOF
endif
