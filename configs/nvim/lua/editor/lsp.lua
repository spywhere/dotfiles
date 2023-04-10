local bindings = require('lib.bindings')
local registry = require('lib.registry')

registry.defer_first(function ()
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
        function () return vim.lsp.buf.format { async = true } end
      }
    )
end)
