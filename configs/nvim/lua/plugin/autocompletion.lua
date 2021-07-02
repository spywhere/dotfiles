local bindings = require('lib/bindings')
local registry = require('lib/registry')
local lsp = require('lib/lsp')

registry.install {
  'neovim/nvim-lspconfig',
  defer = lsp.setup,
  config = function ()
    lsp.on_setup(function ()
      vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
      vim.lsp.diagnostic.on_publish_diagnostics, {
        -- Enable underline, use default values
        underline = true,
        -- Enable virtual text, override spacing to 4
        virtual_text = false,
        -- Use a function to dynamically turn signs off
        -- and on, using buffer local variables
        signs = { priority = 30 },
        -- Disable a feature
        update_in_insert = false,
      }
      )
    end)

    lsp.on_attach(function (client)
      if not client.resolved_capabilities.document_highlight then
        return
      end

      bindings.highlight.link('LspReferenceRead', 'CursorColumn')
      bindings.highlight.link('LspReferenceText', 'CursorColumn')
      bindings.highlight.link('LspReferenceWrite', 'CursorColumn')
      registry.group(function ()
        registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
        registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
      end)
    end)
  end
}

registry.install {
  'onsails/lspkind-nvim',
  config = function ()
    -- symbol icon for completion items
    lsp.on_setup(require('lspkind').init)
  end
}

registry.install {
  'hrsh7th/nvim-compe',
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
    bindings.map.normal('<leader>d', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>')
    bindings.map.normal('<leader>D', '<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>')
    bindings.map.normal('[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>')
    bindings.map.normal(']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<cr>')

    local sign_symbols = {
      Error = '•',
      Warning = '•',
      Information = '•',
      Hint = '•'
    }
    for severity, symbol in pairs(sign_symbols) do
      bindings.sign.define(string.format('LspDiagnosticsSign%s', severity), {
        text = symbol,
        texthl = string.format('LspDiagnostics%s', severity),
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
          nvim_treesitter = true
        }
      })

    end)
  end
}

registry.install {
  'ray-x/lsp_signature.nvim',
  config = function ()
    lsp.on_attach(function ()
      require('lsp_signature').on_attach({
        hint_enable = false,
      })
    end)
  end
}
