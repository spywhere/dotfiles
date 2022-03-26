local registry = require('lib.registry')

-- Currently use FZF as a fallback for Telescope / Snap
registry.experiment('fzf', true)
-- Experiment between scrollbar.nvim and nvim-scrollview
registry.experiment('scrollview', false)
-- Experiment between vim-startify and alpha-nvim
registry.experiment('startify', false)
