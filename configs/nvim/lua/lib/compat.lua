-- backward-compatibility layer for stable build from nightly one
local M = {}

M.is_nightly = function ()
  return fn.has('nvim-0.6') == 1
end

M.get_lsp_highlight = function (severity, kind)
  if M.is_nightly() then
    return string.format('Diagnostic%s%s', kind or '', severity)
  else
    return string.format('LspDiagnostics%s%s', kind or '', severity)
  end
end

return M
