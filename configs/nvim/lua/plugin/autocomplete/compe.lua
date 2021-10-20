local bindings = require('lib/bindings')
local registry = require('lib/registry')
local lsp = require('lib/lsp')
local compat = require('lib/compat')

registry.install {
  'hrsh7th/nvim-compe',
  skip = registry.experiment('cmp').on,
  config = function ()
    bindings.set('completeopt', 'menuone,noinsert,noselect')

    bindings.map.insert(
      '<C-Space>',
      'compe#complete()',
      { expr = true }
    )
    bindings.map.insert(
      '<tab>',
      'pumvisible() ? "\\<C-n>" : "\\<tab>"',
      { expr = true }
    )
    bindings.map.insert(
      '<S-tab>',
      'pumvisible() ? "\\<C-p>" : "\\<C-h>"',
      { expr = true }
    )
    bindings.map.insert(
      '<cr>',
      'pumvisible() ? compe#confirm(\'<cr>\') : "\\<cr>"',
      { expr = true }
    )

    bindings.map.normal('gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')
    bindings.map.normal('gd', '<cmd>lua vim.lsp.buf.definition()<cr>')
    bindings.map.normal('K', '<cmd>lua vim.lsp.buf.hover()<cr>')
    bindings.map.normal('gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')
    bindings.map.normal('ga', '<cmd>lua vim.lsp.buf.code_action()<cr>')
    -- conflicted with tmux navigator, try using through 'gk' instead
    -- bindings.map.normal('<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
    bindings.map.normal('<leader>td', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
    bindings.map.normal('<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>')
    bindings.map.normal('gr', '<cmd>lua vim.lsp.buf.references()<cr>')
    bindings.map.normal('<leader>d', '<cmd>lua vim.diagnostic.open_float(0, { scope = \'line\' })<cr>')
    bindings.map.normal('<leader>D', '<cmd>lua vim.diagnostic.setloclist()<cr>')
    bindings.map.normal('[d', '<cmd>lua vim.diagnostic.goto_prev { float = {} }<cr>')
    bindings.map.normal(']d', '<cmd>lua vim.diagnostic.goto_next { float = {} }<cr>')

    local sign_symbols = {
      Error = '•',
      Warning = '•',
      Information = '•',
      Hint = '•'
    }
    for severity, symbol in pairs(sign_symbols) do
      bindings.sign.define(compat.get_lsp_highlight(severity, 'Sign'), {
        text = symbol,
        texthl = compat.get_lsp_highlight(severity),
        linehl = '',
        numhl = ''
      })
    end

    bindings.cmd(
      'Format',
      {
        vim.lsp.buf.formatting
      }
    )

    lsp.on_setup(function ()
      -- completion popup
      require('compe').setup({
        -- tmux integration?
        source = {
          path = true,
          buffer = true,
          calc = true,
          nvim_lsp = true,
          nvim_lua = true,
          nvim_treesitter = true,
          luasnip = true
        }
      })

    end)
  end
}
