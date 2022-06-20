local registry = require('lib.registry')

-- Experiment between scrollbar.nvim and nvim-scrollview
registry.experiment('scroll', 'satellite')
-- Experiment between vim-startify and alpha-nvim
registry.experiment('startify', false)
-- Experiment between vim-doge and neogen
registry.experiment('doge', false)
-- Experiment of removing rooter plugin
registry.experiment('rooter', false)
-- Experiment between fzf-lua and telescope
registry.experiment('fzf', fn.has('win32') == 0)
