local lsp = require('lib.lsp')
local bindings = require('lib.bindings')
local logger = require('lib.logger')
local shell = require('lib.shell')

local path_join = function (...)
  return table.concat({ ... }, '/')
end

local install_omnisharp = function (force)
  local omnisharp_url = {
    'https://github.com',
    'OmniSharp',
    'omnisharp-roslyn',
    'releases',
    'latest',
    'download',
    'omnisharp-%s.zip'
  }

  local base_install_dir = path_join(
    fn.stdpath('cache'),
    'lspconfig'
  )
  local install_dir = path_join(base_install_dir, 'omnisharp')

  local url = 'linux-x64-net6.0'
  local dll_name = 'Omnisharp.dll'

  if fn.has('mac') == 1 then
    url = 'osx-arm64-net6.0'
  end

  local dll_path = path_join(install_dir, dll_name)
  local omnisharp_run_command = {
    'dotnet', dll_path
  }

  local download_target = path_join(
    install_dir,
    string.format("omnisharp-%s.zip", url)
  )

  local commands = {
    {
      error = 'Error while preparing to install omnisharp',
      command = function ()
        fn.mkdir(install_dir, 'p')
      end
    },
    {
      message = string.format('Downloading omnisharp (%s)...', url),
      error = 'Error while downloading omnisharp',
      command = 'curl',
      options = {
        args = {
          '-fLo',
          download_target,
          '--create-dirs',
          string.format(
            table.concat(omnisharp_url, '/'),
            url
          )
        }
      }
    },
    {
      message = 'Installing omnisharp...',
      error = 'Error while installing omnisharp: <msg>',
      command = 'unzip',
      options = {
        args = {
          '-o',
          download_target,
          '-d',
          install_dir
        }
      }
    }
  }

  table.insert(commands, {
    message = 'Cleaning up downloaded files...',
    error = 'Error while cleaning up downloaded files',
    command = 'rm',
    options = {
      args = {
        '-f',
        download_target
      }
    }
  })

  table.insert(commands, 1, {
    message = 'Cleaning up previous installation...',
    error = 'Error while cleaning up previous installation files',
    command = 'rm',
    options = {
      args = {
        '-rf',
        install_dir
      }
    }
  })

  if force ~= nil then
    if not force and fn.filereadable(dll_path) == 1 then
      logger.inline.info('Omnisharp is already installed')
      return
    end
    if fn.executable('curl') == 0 then
      logger.inline.error('Need "curl" to install omnisharp language server.')
      return
    end
    if fn.executable('unzip') == 0 then
      logger.inline.error('Need "unzip" to install omnisharp language server.')
      return
    end
    local install_word = 'installed'
    if force then
      install_word = string.format('re%s', install_word)
    end
    shell.iterate_commands(
    commands, string.format('Omnisharp has been %s', install_word)
    )
  end

  return omnisharp_run_command
end

lsp.setup('omnisharp')
  .prepare(install_omnisharp)
  .need_executable('dotnet')
  .options(function ()
    return {
      handlers = {
        ['textDocument/definition'] = require('omnisharp_extended').handler
      }
    }
  end)
  .command(function (command)
    -- table.insert(command, '--languageserver')
    -- table.insert(command, '-z')
    -- local pid = fn.getpid()
    --
    -- solution
    -- table.insert(command, '-s')
    -- table.insert(command, '<path to sln file>')
    --
    -- table.insert(command, '--hostPID')
    -- table.insert(command, tostring(pid))
    -- table.insert(command, 'DotNet:enablePackageRestore=false')
    -- table.insert(command, '--encoding')
    -- table.insert(command, 'utf-8')
    --
    -- exclude paths
    -- table.insert(command, 'FileOptions:SystemExcludeSearchPatterns:<index>=<path>')
    --
    -- table.insert(command, 'MsBuild:LoadProjectsOnDemand=true')
    -- table.insert(command, 'RoslynExtensionsOptions:EnableAnalyzersSupport=true')
    -- table.insert(command, 'FormattingOptions:EnableEditorConfigSupport=true')
    --
    -- See: https://github.com/OmniSharp/omnisharp-vscode/blob/1d477d2e0495a9a7d76c7856dc4fe1a46343b7e1/src/omnisharp/server.ts#L380
    table.insert(command, 'RoslynExtensionsOptions:EnableDecompilationSupport=true')
    if fn.executable('asdf') == 1 then
      local sdk = string.gsub(fn.system('asdf where dotnet-core'), '[ \n]*$', '')

      if string.find(sdk, 'No such plugin') == nil then
        table.insert(command, string.format('Sdk:Path=\'%s/sdk\'', sdk))
      end
    end
    return command
  end)
  .on.setup(function ()
    bindings.cmd('OmnisharpInstall', {
      function () install_omnisharp(false) end
    })
    bindings.cmd('OmnisharpReinstall', {
      function () install_omnisharp(true) end
    })
  end)
