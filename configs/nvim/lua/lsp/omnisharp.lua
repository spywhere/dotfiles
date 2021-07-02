local lsp = require('lib/lsp')
local bindings = require('lib/bindings')
local logger = require('lib/logger')
local shell = require('lib/shell')

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

  local util = require('lspconfig/util')

  local base_install_dir = util.path.join(
    fn.stdpath('cache'),
    'lspconfig'
  )
  local install_dir = util.path.join { base_install_dir, 'omnisharp' }

  local url = 'linux-x64'
  local bin_name = 'run'
  local update_bin_permission = true

  if fn.has('win32') == 1 then
    url = 'win-x64'
    bin_name = 'OmniSharp.exe'
    update_bin_permission = false
  elseif fn.has('mac') == 1 then
    url = 'osx'
    bin_name = 'run'
    update_bin_permission = true
  end

  -- use mono version if mono is installed
  if util.has_bins('mono') then
    url = 'mono'
    bin_name = 'OmniSharp.exe'
    update_bin_permission = false
  end

  local bin_path = util.path.join { install_dir, bin_name }
  local omnisharp_run_command = {
    bin_path
  }

  if url == 'mono' then
    omnisharp_run_command = {
      'mono', bin_path
    }
  end

  local download_target = util.path.join {
    install_dir,
    string.format("omnisharp-%s.zip", url)
  }

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

  if update_bin_permission then
    table.insert(commands, {
      error = 'Error while making omnisharp executable',
      command = 'chmod',
      options = {
        args = {
          'u+x',
          bin_path
        }
      }
    })
  end

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

  if force or not util.path.exists(bin_path) then
    if not (util.has_bins('curl')) then
      logger.inline.error('Need "curl" to install omnisharp language server.')
      return
    end
    if not (util.has_bins('unzip')) then
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
  .command(function (command)
    local pid = fn.getpid()
    -- solution
    -- table.insert(command, '-s')
    -- table.insert(command, '<path to sln file>')
    table.insert(command, '--languageserver')
    table.insert(command, '--hostPID')
    table.insert(command, tostring(pid))
    -- exclude paths
    -- table.insert(command, 'FileOptions:SystemExcludeSearchPatterns:<index>=<path>')
    -- table.insert(command, 'MsBuild:LoadProjectsOnDemand=true')
    -- table.insert(command, 'RoslynExtensionsOptions:EnableAnalyzersSupport=true')
    -- table.insert(command, 'FormattingOptions:EnableEditorConfigSupport=true')
    -- table.insert(command, 'RoslynExtensionsOptions:EnableDecompilationSupport=true')
    return command
  end)
  .on.setup(function ()
      bindings.cmd('OmnisharpReinstall', {
        function ()
          install_omnisharp(true)
        end
      })
  end)
