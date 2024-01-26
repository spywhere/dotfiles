local bindings = require('lib.bindings')
local registry = require('lib.registry')
local dap = require('lib.dap')

registry.install {
  'jay-babu/mason-nvim-dap.nvim',
  requires = {
    'williamboman/mason.nvim',
    'mfussenegger/nvim-dap',
  },
  delay = dap.setup(function (handler)
    local mason_dap = require('mason-nvim-dap')

    mason_dap.setup {
      automatic_installation = true,
      handlers = {
        function (config)
          local adapters
          handler(config.name, {
            adapter = function (_, adapter)
              adapters = adapter
            end
          })

          config.adapters = vim.tbl_extend('force', config.adapters, adapters)

          mason_dap.default_setup(config)
        end
      }
    }
  end),
  config = function ()
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
    bindings.map.normal('<leader>dx', {
      import='dap',
      'terminate()'
    })
  end
}
