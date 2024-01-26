local lsp = require('lib.lsp')
local dap = require('lib.dap')

lsp.setup('sourcekit')
  .need_executable('sourcekit-lsp')
  .root(function (filename)
    local util = require('lspconfig.util')
    return util.root_pattern('buildServer.json')(filename)
      or util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
      or util.find_git_ancestor(filename)
      or util.root_pattern('Package.swift')(filename)
  end)

dap.setup('codelldb')
  .ft('swift', function ()
    local xcodebuild = require('xcodebuild.dap')

    return {
      name = 'iOS App Debugger',
      type = 'codelldb',
      request = 'attach',
      program = xcodebuild.get_program_path,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      waitFor = true
    }
  end)
