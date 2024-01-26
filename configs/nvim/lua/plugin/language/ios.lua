local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'wojciech-kulik/xcodebuild.nvim',
  requires = {
    'nvim-telescope/telescope.nvim',
    'MunifTanjim/nui.nvim'
  },
  delay = function ()
    local xcodebuild = require('xcodebuild.dap')
    local dap = prequire('dap')

    if not dap then
      return
    end

    bindings.map.normal('<leader>dd', xcodebuild.build_and_debug)
    bindings.map.normal('<leader>dr', xcodebuild.debug_without_build)

    dap.listeners.before.event_terminated.xcodebuild_config = function ()
      require('xcodebuild.actions').cancel()
    end
  end,
  config = function ()
    require('xcodebuild').setup {
      code_coverage = {
        enabled = true
      }
    }

    bindings.map.normal('<leader>X', '<cmd>XcodebuildPicker<cr>')

    bindings.map.normal('<leader>xb', '<cmd>XcodebuildBuild<cr>')
    bindings.map.normal('<leader>xr', '<cmd>XcodebuildBuildRun<cr>')
    bindings.map.normal('<leader>xl', '<cmd>XcodebuildToggleLogs<cr>')

    bindings.map.normal('<leader>xt', '<cmd>XcodebuildTest<cr>')
    bindings.map.normal('<leader>xT', '<cmd>XcodebuildTestClass<cr>')
    bindings.map.normal('<leader>xc', '<cmd>XcodebuildToggleCodeCoverage<cr>')
    bindings.map.normal('<leader>xC', '<cmd>XcodebuildShowCodeCoverageReport<cr>')

    bindings.map.normal('<leader>xd', '<cmd>XcodebuildSelectDevice<cr>')
    bindings.map.normal('<leader>xp', '<cmd>XcodebuildSelectTestPlan<cr>')
  end
}
