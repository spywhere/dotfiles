local bindings = require('lib.bindings')
local registry = require('lib.registry')
local dap = require('lib.dap')

registry.install {
  'mfussenegger/nvim-dap',
  delay=dap.setup,
  config=function ()
    bindings.map.normal('<leader>b', {
      import='dap',
      'toggle_breakpoint()'
    })
    bindings.map.normal('<leader>B', {
      import='dap',
      'set_breakpoint(vim.fn.input(\'Breakpoint condition: \'))'
    })

    bindings.map.normal('<leader>dc', {
      import='dap',
      'continue()'
    })
    bindings.map.normal('<leader>di', {
      import='dap',
      'step_into()'
    })
    bindings.map.normal('<leader>do', {
      import='dap',
      'step_out()'
    })
    bindings.map.normal('<leader>dv', {
      import='dap',
      'step_over()'
    })
  end
}
