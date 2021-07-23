local registry = require('lib/registry')

registry.install {
  'editorconfig/editorconfig-vim',
  config = function ()
    vim.g.Editorconfig_exclude_patterns = { 'fugitive://.*', 'scp://.*' }
  end
}
