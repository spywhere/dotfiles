local lsp = require('lib/lsp')
local bindings = require('lib/bindings')
local logger = require('lib/logger')
local shell = require('lib/shell')

local install_lualsp = function (force)
  local lualsp_repo = {
    'https://github.com',
    'sumneko',
    'lua-language-server'
  }
  local util = require('lspconfig/util')

  local base_install_dir = util.path.join(
    fn.stdpath('cache'),
    'lspconfig'
  )
  local install_dir = util.path.join { base_install_dir, 'lualsp' }

  local luamake_bin = './3rd/luamake/luamake'
  local luamake_dir = '3rd/luamake'
  local luamake_build = './compile/install.sh'
  local platform = 'Linux'
  if fn.has('mac') == 1 then
    platform = 'macOS'
  end
  local bin_name = string.format('bin/%s/lua-language-server', platform)

  if fn.has('win32') == 1 then
    luamake_bin = '3rd\\luamake\\luamake.exe'
    luamake_dir = '3rd\\luamake'
    luamake_build = 'compile\\install.bat'
    bin_name = 'bin\\Windows\\lua-language-server.exe'
  end

  local bin_path = util.path.join { install_dir, bin_name }
  local lualsp_run_command = {
    bin_path,
    '-E',
    util.path.join { install_dir, 'main.lua' }
  }

  local commands = {}

  if
    force or
    (fn.isdirectory(install_dir) and not util.path.exists(bin_path))
  then
    table.insert(commands, {
      message = 'Cleaning up previously downloaded files',
      error = 'Error while cleaning up previously downloaded files',
      command = 'rm',
      options = {
        args = {
          '-rf',
          install_dir
        }
      }
    })
  end

  table.insert(commands, {
    message = 'Cloning lua language server...',
    error = 'Error while cloning lua language server',
    command = 'git',
    options = {
      args = {
        'clone',
        table.concat(lualsp_repo, '/'),
        install_dir
      }
    }
  })
  table.insert(commands, {
    message = 'Updating submodules...',
    error = 'Error while updating submodules',
    command = 'git',
    options = {
      cwd = install_dir,
      args = {
        'submodule',
        'update',
        '--init',
        '--recursive'
      }
    }
  })
  table.insert(commands, {
    message = 'Compiling luamake...',
    error = 'Error while compiling luamake: <msg>',
    command = luamake_build,
    options = {
      cwd = util.path.join { install_dir, luamake_dir }
    }
  })
  table.insert(commands, {
    message = 'Building lua language server...',
    error = 'Error while building lua language server: <msg>',
    command = luamake_bin,
    options = {
      cwd = install_dir
    }
  })

  if force or not util.path.exists(bin_path) then
    if not (util.has_bins('git')) then
      logger.inline.error('Need "git" to install lua language server.')
      return
    end
    if not (util.has_bins('ninja')) then
      logger.inline.info('Need "ninja" to install lua language server.')
      return
    end
    local install_word = 'installed'
    if force then
      install_word = string.format('re%s', install_word)
    end
    shell.iterate_commands(
      commands,
      string.format('Lua language server has been %s', install_word)
    )
  end

  return lualsp_run_command
end

lsp.setup('sumneko_lua')
  .prepare(install_lualsp)
  .command(function (command)
    return command
  end)
  .options({
    settings = {
      Lua = {
        diagnostics = {
          globals = {
            'vim'
          }
        }
      }
    }
  })
  .on.setup(function ()
      bindings.cmd('LuaLSPReinstall', {
        function ()
          install_lualsp(true)
        end
      })
  end)
