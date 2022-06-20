local registry = require('lib.registry')

-- Experiment between scrollbar.nvim, nvim-scrollview and satellite.nvim
registry.experiment('scroll', 'satellite')
-- Experiment between fzf-lua and telescope
registry.experiment('fzf', fn.has('win32') == 0)
