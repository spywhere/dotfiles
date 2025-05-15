local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'mason-org/mason-lspconfig.nvim',
  requires = {
    'mason-org/mason.nvim',
    'neovim/nvim-lspconfig'
  },
  delay = lsp.setup(function (handler, required_servers)
    local mason_lsp = require('mason-lspconfig')
    mason_lsp.setup {
      ensure_installed = {
        'bashls', 'emmet_ls', 'eslint', 'graphql', 'lua_ls', 'pyright', 'ts_ls', 'vimls', 'yamlls'
      },
      automatic_enable = false,
      handlers = fn.has('nvim-0.11') == 0 and { function (name)
        return handler(name, { skip_check = true })
      end } or nil
    }

    for _, server in ipairs(required_servers) do
      local available_servers = mason_lsp.get_available_servers()
      if fn.has('nvim-0.11') == 1 then
        -- setup all the required servers, extending mason configs
        handler(server)
      elseif not available_servers[server] then
        handler(server)
      end
    end
  end),
  config = function ()
    lsp.on_setup(function ()
      vim.diagnostic.config({
        virtual_text = false
      })
    end)

    lsp.on_attach(function (client)
      if fn.has('nvim-0.8') == 1 and not client.server_capabilities.documentHighlightProvider then
        return
      elseif fn.has('nvim-0.8') == 0 and not client.resolved_capabilities.document_highlight then
        return
      end

      registry.group(function ()
        registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
        registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
      end)
    end)
  end
}
