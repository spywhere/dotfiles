local registry = require('lib.registry')

registry.install {
  'rcarriga/nvim-dap-ui',
  requires = {
    'mfussenegger/nvim-dap',
    'nvim-neotest/nvim-nio'
  },
  delay = function ()
    local dap = require('dap')
    local dapui = require('dapui')

    dap.listeners.before.attach.dapui_config = function () dapui.open() end
    dap.listeners.before.launch.dapui_config = function () dapui.open() end
    dap.listeners.after.event_terminated.dapui_config = function () dapui.close() end
    dap.listeners.after.event_exited.dapui_config = function () dapui.close() end
  end,
  config = function ()
    local dapui = require('dapui')
    dapui.setup {}
  end
}
