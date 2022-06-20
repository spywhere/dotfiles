local registry = require('lib.registry')

-- Experiment between scrollbar.nvim and nvim-scrollview
registry.experiment('scroll', 'satellite')
-- Experiment between fzf-lua and telescope
registry.experiment('fzf', fn.has('win32') == 0)
