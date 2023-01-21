local registry = require('lib.registry')

registry.install {
  'github/copilot.vim',
  skip = registry.experiment('copilot').off,
  setup = function ()
    vim.g.copilot_no_tab_map = 1
    vim.g.copilot_assume_mapped = 1
    vim.g.copilot_tab_fallback = ''
  end
}
