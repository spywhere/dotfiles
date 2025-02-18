local registry = require('lib.registry')

registry.pre(function ()
  local disable_plugins = {
    'netrw',
    'netrwPlugin',
    'netrwSettings',
    'netrwFileHandlers',
    'gzip',
    'zip',
    'zipPlugin',
    'tar',
    'tarPlugin',
    'getscript',
    'getscriptPlugin',
    'vimball',
    'vimballPlugin',
    'logipat',
    'rrhelper',
    'spellfile_plugin',
    'matchit'
  }

  for _, plugin in pairs(disable_plugins) do
    vim.g['loaded_' .. plugin] = 1
  end
end)
