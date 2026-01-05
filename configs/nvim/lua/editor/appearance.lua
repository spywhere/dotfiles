local bindings = require('lib.bindings')
local registry = require('lib.registry')

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
  registry.auto('BufEnter', vim.schedule_wrap(function ()
    if vim.list_contains({
      'dbout', 'dbui', 'qf', 'help', 'alpha'
    }, vim.bo.filetype) then
      return
    end

    vim.cmd('match ColorColumn /\\%80v./')
  end))
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
  bindings.set('fillchars', '+=', 'eob: ')
end
registry.pre(indicators)

local messages = function ()
  -- don't give |ins-completion-menu| messages
  bindings.set('shortmess', '+=', 'c')
end
registry.pre(messages)

local statusline = function ()
  -- always show status line and tab line
  if fn.has('nvim-0.7') == 1 then
    -- use unified status line when possible
    bindings.set('laststatus', 3)
  else
    bindings.set('laststatus', 2)
  end
  if fn.has('nvim-0.8') == 1 then
    bindings.set('cmdheight', 0)
  else
    bindings.set('cmdheight', 1)
  end
end
-- for first time setup
registry.pre(statusline)
-- override `laststatus` set by sensible.vim
registry.defer(statusline)

local netrw = function ()
  vim.g.loaded_netrwPlugin = 1
end
registry.defer_first(netrw)

local highlight_yank = function ()
  local highlight = prequire('vim.hl') or prequire('vim.highlight')
  if not highlight then
    return
  end
  highlight.on_yank({ timeout = 300 })
end
registry.auto('TextYankPost', highlight_yank, nil, 'silent!')

registry.post(function ()
  bindings.set('winblend', 10)

  if fn.has('termguicolors') == 1 then
    bindings.set('termguicolors')
  end
end)
