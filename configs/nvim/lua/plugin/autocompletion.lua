local bindings = require('lib/bindings')
local registry = require('lib/registry')
local logger = require('lib/logger')

registry.install('neovim/nvim-lspconfig')
registry.install('onsails/lspkind-nvim')
registry.install('hrsh7th/nvim-compe')
-- tmux integration?
registry.post(function ()
  bindings.set('completeopt', 'menuone,noinsert,noselect')

  bindings.map.insert(
    '<C-Space>',
    'compe#complete()',
    { expr = true }
  )
  bindings.map.insert(
    '<tab>',
    'pumvisible() ? "\\<C-n>" : "\\<tab>"',
    { expr = true }
  )
  bindings.map.insert(
    '<S-tab>',
    'pumvisible() ? "\\<C-p>" : "\\<C-h>"',
    { expr = true }
  )
  bindings.map.insert(
    '<cr>',
    'pumvisible() ? compe#confirm(\'<cr>\') : "\\<cr>"',
    { expr = true }
  )

  bindings.map.normal('gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')
  bindings.map.normal('gd', '<cmd>lua vim.lsp.buf.definition()<cr>')
  bindings.map.normal('K', '<cmd>lua vim.lsp.buf.hover()<cr>')
  bindings.map.normal('gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')
  bindings.map.normal('ga', '<cmd>lua vim.lsp.buf.code_action()<cr>')
  bindings.map.normal('<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
  bindings.map.normal('<leader>td', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
  bindings.map.normal('<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>')
  bindings.map.normal('gr', '<cmd>lua vim.lsp.buf.references()<cr>')
  bindings.map.normal('<leader>d', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>')
  bindings.map.normal('<leader>D', '<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>')
  bindings.map.normal('[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>')
  bindings.map.normal(']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<cr>')

  local sign_symbols = {
    Error = '•',
    Warning = '•',
    Information = '•',
    Hint = '•'
  }
  for severity, symbol in pairs(sign_symbols) do
    bindings.sign.define(string.format('LspDiagnosticsSign%s', severity), {
      text = symbol,
      texthl = string.format('LspDiagnostics%s', severity),
      linehl = '',
      numhl = ''
    })
  end

  bindings.cmd(
    'Format',
    {
      vim.lsp.buf.formatting
    }
  )
end)

local _M = {}
_M.iterate_commands = function (commands, index, success)
  if index == vim.tbl_count(commands) then
    vim.cmd('redraw')
    vim.cmd('echo ' .. string.format('%q', success))
    return
  end

  local command = commands[index]

  if command.message then
    vim.cmd('redraw')
    vim.cmd('echo ' .. string.format('%q', command.message))
  end

  if type(command.command) == 'function' then
    local ok, error = pcall(command.command)
    if ok then
      _M.iterate_commands(commands, index + 1, success)
    else
      logger.error(command.error ..'\n'..vim.inspect(error))
      return
    end
  else
    local handle
    handle = luv.spawn(
      command.command,
      command.options,
      vim.schedule_wrap(function(code)
        handle:close()
        if code ~= 0 then
          local execute_cmd = command.command
          if command.options and command.options.args then
            execute_cmd = string.format(
              '%s %s', execute_cmd, table.concat(command.options.args, ' ')
            )
          end
          logger.error(string.gsub(command.error, '<msg>', execute_cmd) ..'\n')
        end
        _M.iterate_commands(commands, index + 1, success)
      end)
    )
  end
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
      error('Need "curl" to install omnisharp language server.')
      return
    end
    if not (util.has_bins('unzip')) then
      error('Need "unzip" to install omnisharp language server.')
      return
    end
    local install_word = 'installed'
    if force then
      install_word = string.format('re%s', install_word)
    end
    _M.iterate_commands(
      commands, 1, string.format('Omnisharp has been %s', install_word)
    )
  end

  return omnisharp_run_command
end

local setup_lsps = function ()
  bindings.cmd('OmnisharpReinstall', {
    function ()
      install_omnisharp(true)
    end
  })

  local lsps = {
    clangd = {
      executable = 'clangd'
    },
    bashls = {
      executable = 'bash-language-server'
    },
    metals = {
      executable = 'metals'
    },
    omnisharp = {
      pre = install_omnisharp,
      cmd = function (command)
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
      end
    },
    tsserver = {
      executable = 'typescript-language-server'
    },
    vimls = {
      executable = 'vim-language-server'
    }
  }

  local nvim_lsp = require('lspconfig')
  local on_attach = function (client, bufnr)
    if not client.resolved_capabilities.document_highlight then
      return
    end

    bindings.highlight.link('LspReferenceRead', 'CursorColumn')
    bindings.highlight.link('LspReferenceText', 'CursorColumn')
    bindings.highlight.link('LspReferenceWrite', 'CursorColumn')
    registry.group(function ()
      registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
      registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
    end)
  end

  local setup_lsp = function (name, options)
    local options = options or {}
    if options.executable and not bindings.executable(options.executable) then
      return
    end

    local pre_value = {}
    if options.pre and type(options.pre) == 'function' then
      pre_value = options.pre()
    end

    if not pre_value then
      return
    end

    if options.cmd then
      options.cmd = options.cmd(pre_value)
    end

    options.on_attach = on_attach
    nvim_lsp[name].setup(options)
  end

  for name, options in pairs(lsps) do
    if type(name) == 'number' then
      setup_lsp(options)
    else
      setup_lsp(name, options)
    end
  end

  vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      -- Enable underline, use default values
      underline = true,
      -- Enable virtual text, override spacing to 4
      virtual_text = false,
      -- Use a function to dynamically turn signs off
      -- and on, using buffer local variables
      signs = { priority = 30 },
      -- Disable a feature
      update_in_insert = false,
    }
  )

  -- completion popup
  require('compe').setup({
    source = {
      path = true,
      buffer = true,
      calc = true,
      nvim_lsp = true,
      nvim_lua = true,
      nvim_treesitter = true
    }
  })
  -- symbol icon for completion items
  require('lspkind').init()
end
registry.defer(setup_lsps)
