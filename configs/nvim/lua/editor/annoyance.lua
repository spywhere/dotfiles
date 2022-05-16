local bindings = require('lib.bindings')
local registry = require('lib.registry')

registry.pre(function ()
  -- improve startup time (https://github.com/neovim/neovim/issues/2437)
  if fn.has('win32') == 0 then
    vim.g.python_host_prog = '~/.asdf/shims/python'
    vim.g.python3_host_prog = '~/.asdf/shims/python3'
  end
end)

registry.defer_first(function ()
  bindings.map.normal('Q')

  bindings.map.ni('<PageUp>')
  bindings.map.ni('<PageDown>')

  bindings.map.ni('<A-PageUp>')
  bindings.map.ni('<A-PageDown>')

  bindings.map.ni('<S-PageUp>')
  bindings.map.ni('<S-PageDown>')

  bindings.map.ni('<A-S-PageUp>')
  bindings.map.ni('<A-S-PageDown>')

  local bang_cmd = function (cmd)
    return {
      function (attrs)
        vim.cmd(cmd .. (attrs.bang and '!' or ''))
      end,
      bang = true
    }
  end

  bindings.cmd('Q', bang_cmd('quit'))
  bindings.cmd('Qa', bang_cmd('quitall'))
  bindings.cmd('QA', bang_cmd('quitall'))

  bindings.cmd('Vs', bang_cmd('vsplit'))
  bindings.cmd('Sp', bang_cmd('split'))
end)
