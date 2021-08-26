local registry = require('lib/registry')

-- Currently use FZF as a fallback for Telescope / Snap
registry.experiment('fzf', true)
-- Experiment between Telescope / Snap
registry.experiment('telescope', true)
-- Experiment between nvim-cmp / nvim-compe
registry.experiment('cmp', true)
