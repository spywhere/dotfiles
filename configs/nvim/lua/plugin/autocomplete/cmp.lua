local bindings = require('lib/bindings')
local registry = require('lib/registry')
local lsp = require('lib/lsp')

registry.install {
  'hrsh7th/nvim-cmp',
  config = function ()
    bindings.set('completeopt', 'menuone,noinsert,noselect')

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
      bindings.sign.define(string.format('DiagnosticSign%s', severity), {
        text = symbol,
        texthl = string.format('Diagnostic%s', severity),
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
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function (args)
            local luasnip = prequire('luasnip')
            if luasnip then
              luasnip.lsp_expand(args.body)
            end
          end
        },
        formatting = {
          format = function (entry, item)
            local lspkind = prequire('lspkind')

            if not lspkind then
              return item
            end

            -- fancy icons and a name of kind
            item.kind = lspkind.presets.default[item.kind]
            -- set a name for each source
            item.menu = ({
              buffer = 'Buffer',
              nvim_lsp = 'LSP',
              luasnip = 'LuaSnip',
              nvim_lua = 'Lua',
              latex_symbols = 'Latex',
            })[entry.source.name]
            return item
          end
        },
        mapping = {
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.close(),
          ['<cr>'] = cmp.mapping.confirm {},
          ['<tab>'] = cmp.mapping(function (fallback)
            local luasnip = prequire('luasnip')
            local copilot_key = fn['copilot#Accept']()
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip and luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif copilot_key ~= "" then
              api.nvim_feedkeys(copilot_key, 'i', true)
            else
              fallback()
            end
          end, { 'i', 's', 'c'}),
          ['<S-tab>'] = cmp.mapping(function (fallback)
            local luasnip = prequire('luasnip')
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip and luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's', 'c' })
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'nvim_lua' },
          { name = 'luasnip' },
          -- { name = 'nvim_treesitter' },
          { name = 'buffer', keyword_length = 3, max_item_count = 8 },
          { name = 'path' },
          { name = 'calc' }
        }
      })

      cmp.setup.cmdline('/', {
        sources = {
          { name = 'buffer', keyword_length = 3 }
        }
      })

      cmp.setup.cmdline(':', {
        sources = {
          { name = 'path', keyword_length = 3 },
          { name = 'cmdline', keyword_length = 3 }
        }
      })
    end)
  end
}
