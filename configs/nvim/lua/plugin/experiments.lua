local registry = require('lib.registry')

-- Experiment between scrollbar.nvim, nvim-scrollview and satellite.nvim
registry.experiment('scroll', 'satellite')
-- Experiment between fzf-lua and telescope
registry.experiment('fuzzy', 'telescope')
-- Experiment between vim-surround and nvim-surround
registry.experiment('surround', false)
