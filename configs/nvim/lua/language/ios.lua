local lsp = require('lib.lsp')
local dap = require('lib.dap')

lsp.setup('sourcekit')
  .need_executable('sourcekit-lsp')
  .command(function ()
    local command = 'sourcekit-lsp'
    if fn.executable('xcode-select') == 0 then
      return command
    end

    local dev_dir = fn.trim(fn.system('xcode-select -p'))
    local toolchain_dir = dev_dir .. '/Toolchains/XcodeDefault.xctoolchain'
    if fn.isdirectory(toolchain_dir) == 0 then
      return command
    end

    local bin_dir = toolchain_dir .. '/usr/bin'
    if fn.isdirectory(bin_dir) == 0 then
      return command
    end

    local lsp_bin = bin_dir .. '/sourcekit-lsp'
    if fn.executable(lsp_bin) == 0 then
      return command
    else
      return { lsp_bin }
    end
  end)
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
