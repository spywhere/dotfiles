local compat = require('lib/compat')

if not compat.is_nightly() and vim.diagnostic == nil then
  local diagnostic = vim.lsp.diagnostic

  vim.diagnostic = {
    get = function (buffer, options)
      local severity = options.severity

      local output = {}
      for _, diag_type in pairs(vim.diagnostic.severity) do
        if type(severity) == 'table' or diag_type == severity then
          local count = diagnostic.get_count(buffer, diag_type)
          for index = 1, count, 1 do
            table.insert(output, index)
          end
        end
      end
      return output
    end,
    config = function (options)
      vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
        diagnostic.on_publish_diagnostics, options
      )
    end,
    setloclist = diagnostic.set_loclist,
    severity = {
      HINT = 'Hint',
      INFO = 'Info',
      WARN = 'Warn',
      ERROR = 'Error'
    },
    goto_prev = function ()
      diagnostic.goto_prev()
    end,
    goto_next = function ()
      diagnostic.goto_prev()
    end,
    open_float = function (_, options)
      local scope = options.scope

      if scope == 'line' then
        diagnostic.show_line_diagnostics()
      end
    end
  }
end
