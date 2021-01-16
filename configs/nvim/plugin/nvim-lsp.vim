set completeopt=menuone,noinsert,noselect

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    lua vim.lsp.buf.hover()
  endif
endfunction

inoremap <silent><expr> <tab> pumvisible() ? "\<C-n>" : "\<tab>"
inoremap <expr><S-tab> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<cr>"
inoremap <silent><expr> <tab> pumvisible() ? "\<C-n>" : "\<tab>"
inoremap <expr><S-tab> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<cr>"

nnoremap <silent> gD :lua vim.lsp.buf.declaration()<cr>
nnoremap <silent> gd :lua vim.lsp.buf.definition()<cr>
nnoremap <silent> K :lua vim.lsp.buf.hover()<cr>
nnoremap <silent> gi :lua vim.lsp.buf.implementation()<cr>
nnoremap <silent> ga :lua vim.lsp.buf.code_action()<cr>
nnoremap <silent> <C-k> :lua vim.lsp.buf.signature_help()<cr>
nnoremap <silent> <leader>td :lua vim.lsp.buf.type_definition()<cr>
nnoremap <silent> <leader>rn :lua vim.lsp.buf.rename()<cr>
nnoremap <silent> gr :lua vim.lsp.buf.references()<cr>
nnoremap <silent> <leader>d :lua vim.lsp.diagnostic.show_line_diagnostics()<cr>
nnoremap <silent> <leader>D :lua vim.lsp.diagnostic.set_loclist()<cr>
nnoremap <silent> [d :lua vim.lsp.diagnostic.goto_prev()<cr>
nnoremap <silent> ]d :lua vim.lsp.diagnostic.goto_next()<cr>

command! Format execute 'lua vim.lsp.buf.formatting()'

lua << EOF
  local nvim_lsp = require('lspconfig')
  local on_attach = function(client, bufnr)
    require('completion').on_attach(client)
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    if client.resolved_capabilities.document_highlight then
      require('lspconfig').util.nvim_multiline_command [[
        :hi default link LspReferenceRead CursorColumn
        :hi default link LspReferenceText CursorColumn
        :hi default link LspReferenceWrite CursorColumn
        augroup lsp_document_highlight
          autocmd!
          autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
          autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
      ]]
    end
  end

  -- setup a simple language server
  local servers = {'clangd', 'bashls', 'tsserver', 'vimls'}
  for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
      on_attach = on_attach
    }
  end

  -- setup omnisharp language server
  local pid = vim.fn.getpid()
  nvim_lsp.omnisharp.setup{
    cmd = { 'omnisharp', '--languageserver' , '--hostPID', tostring(pid) },
    on_attach = on_attach
  }

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      -- Enable underline, use default values
      underline = true,
      -- Enable virtual text, override spacing to 4
      virtual_text = false,
      -- Use a function to dynamically turn signs off
      -- and on, using buffer local variables
      signs = true,
      -- Disable a feature
      update_in_insert = false,
    }
  )
EOF

let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
let g:completion_chain_complete_list = {
\   'default': {
\     'comment': [],
\     'default': [
\       {
\         'complete_items': [ 'lsp', 'tmux', 'buffers' ]
\       }, {
\         'mode': '<c-p>'
\       }, {
\         'mode': '<c-n>'
\       }
\     ]
\   }
\ }
