local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.defer(function ()
  bindings.map.normal('Q')

  bindings.map.ni('<PageUp>')
  bindings.map.ni('<PageDown>')

  bindings.map.ni('<A-PageUp>')
  bindings.map.ni('<A-PageDown>')

  bindings.map.ni('<S-PageUp>')
  bindings.map.ni('<S-PageDown>')

  bindings.map.ni('<A-S-PageUp>')
  bindings.map.ni('<A-S-PageDown>')

  bindings.cmd('Q', {
    function(modifiers)
      api.nvim_command('quit' .. modifiers[1])
    end,
    bang = true
  })
  bindings.cmd('Qa', {
    function(modifiers)
      api.nvim_command('quitall' .. modifiers[1])
    end,
    bang = true
  })
  bindings.cmd('QA', {
    function(modifiers)
      api.nvim_command('quitall' .. modifiers[1])
    end,
    bang = true
  })
end)