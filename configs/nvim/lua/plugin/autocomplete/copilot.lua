local registry = require('lib/registry')

registry.install {
  'github/copilot.vim',
  setup = function ()
    vim.g.copilot_assume_mapped = 1
  end
}
