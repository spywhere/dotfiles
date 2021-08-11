local bindings = require('lib/bindings')
local registry = require('lib/registry')

local scroll_off = function ()
  local margin = 10

  bindings.set('scrolloff', margin)
  bindings.set('sidescrolloff', margin)
end
registry.defer(scroll_off)

local columns = function ()
  bindings.set('number')
  bindings.set('relativenumber')

  -- always show sign column, resize as needed
  bindings.set('signcolumn', 'auto:1-3')
  -- ruler at 79 chars
  bindings.set('colorcolumn', 79)
end
registry.pre(columns)

local hidden_buffer = function ()
  bindings.set('hidden')
end
registry.defer(hidden_buffer)

local line_wrap = function ()
  bindings.set('nowrap')
end
registry.pre(line_wrap)

local indicators = function ()
  -- use lightline, no need for mode
  bindings.set('noshowmode')

  bindings.set('listchars', 'tab:→\\ ,lead:·,trail:·,nbsp:·')
end
registry.pre(indicators)

local messages = function ()
  -- don't give |ins-completion-menu| messages
  bindings.set('shortmess', '+=', 'c')

  -- always show status line and tab line
  bindings.set('laststatus', 2)
  bindings.set('cmdheight', 1)
end
registry.pre(messages)

local netrw = function ()
  vim.g.loaded_netrwPlugin = 1
end
registry.defer_first(netrw)

local highlight_yank = function ()
  require('vim.highlight').on_yank({ timeout = 300 })
end
registry.auto('TextYankPost', highlight_yank, nil, 'silent!')

registry.post(function ()
  if fn.has('termguicolors') == 1 then
    bindings.set('termguicolors')
  end
end)
