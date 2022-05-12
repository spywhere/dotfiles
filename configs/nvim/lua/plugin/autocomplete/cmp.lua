local bindings = require('lib.bindings')
local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'hrsh7th/nvim-cmp',
  config = function ()
    bindings.set('completeopt', 'menuone,noinsert,noselect')

    bindings.map.normal('gD', { 'vim.lsp.buf.declaration()' })
    bindings.map.normal('gd', { 'vim.lsp.buf.definition()' })
    bindings.map.normal('K', { 'vim.lsp.buf.hover()' })
    bindings.map.normal('gi', { 'vim.lsp.buf.implementation()' })
    bindings.map.normal('ga', { 'vim.lsp.buf.code_action()' })
    -- conflicted with tmux navigator, try using through 'gk' instead
    -- bindings.map.normal('<C-k>', { 'vim.lsp.buf.signature_help()' })
    bindings.map.normal('<leader>td', { 'vim.lsp.buf.type_definition()' })
    bindings.map.normal('<leader>rn', { 'vim.lsp.buf.rename()' })
    bindings.map.normal('gr', { 'vim.lsp.buf.references()' })
    bindings.map.normal('<leader>d', { 'vim.diagnostic.open_float(0, { scope = \'line\' })' })
    bindings.map.normal('<leader>D', { 'vim.diagnostic.setloclist()' })
    bindings.map.normal('[d', { 'vim.diagnostic.goto_prev { float = {} }' })
    bindings.map.normal(']d', { 'vim.diagnostic.goto_next { float = {} }' })

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
      local lspkind = prequire('lspkind')
      local entry_format = function (entry, item) return item end
      if lspkind then
        entry_format = lspkind.cmp_format({
          mode = 'symbol',
          menu = ({
            buffer = 'Buffer',
            nvim_lsp = 'LSP',
            luasnip = 'LuaSnip',
            nvim_lua = 'Lua',
            latex_symbols = 'Latex',
          })
        })
      end
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
          format = entry_format
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
          { name = 'cmdline', keyword_length = 2 }
        }
      })
    end)
  end
}
