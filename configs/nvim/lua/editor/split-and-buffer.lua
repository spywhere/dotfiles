local bindings = require('lib.bindings')
local registry = require('lib.registry')

local split_management = function ()
  -- split resize
  bindings.map.nt('<A-S-Left>', '<cmd>vertical resize -5<cr>')
  bindings.map.nt('<A-S-Right>', '<cmd>vertical resize +5<cr>')
  bindings.map.nt('<A-S-Up>', '<cmd>resize +5<cr>')
  bindings.map.nt('<A-S-Down>', '<cmd>resize -5<cr>')
  bindings.map.normal('<Left>', '<cmd>vertical resize -1<cr>')
  bindings.map.normal('<Right>', '<cmd>vertical resize +1<cr>')
  bindings.map.normal('<Up>', '<cmd>resize +1<cr>')
  bindings.map.normal('<Down>', '<cmd>resize -1<cr>')

  -- quick split
  bindings.map.normal('<leader><Left>', '<cmd>topleft vnew<cr>')
  bindings.map.normal('<leader><Right>', '<cmd>botright vnew<cr>')
  bindings.map.normal('<leader><Up>', '<cmd>topleft new<cr>')
  bindings.map.normal('<leader><Down>', '<cmd>botright new<cr>')
  bindings.map.normal('<leader><Up><Left>', '<cmd>leftabove vnew<cr>')
  bindings.map.normal('<leader><Up><Right>', '<cmd>rightbelow vnew<cr>')
  bindings.map.normal('<leader><Down><Left>', '<cmd>rightbelow new<cr>')
  bindings.map.normal('<leader><Down><Right>', '<cmd>leftabove new<cr>')

  bindings.map.normal('vs', '<cmd>vs<cr>')
  bindings.map.normal('sp', '<cmd>sp<cr>')
end
registry.defer(split_management)

local buffer_management = function ()
  -- switch buffer
  bindings.map.normal('<A-Left>', '<cmd>bprev<cr>')
  bindings.map.normal('<A-Right>', '<cmd>bnext<cr>')

  local close_buffer = function (command, switch_to_last)
    return function ()
      if string.lower(vim.bo.filetype) == 'nvimtree' then
        return
      end

      -- only one buffer left
      if #fn.getbufinfo({ buflisted = 1 }) == 1 then
        return
      end

      local lastwin = fn.winnr()
      local tree_open = false
      local tree_api = prequire('nvim-tree.api')
      if tree_api then
        local tree_view = require('nvim-tree.view')
        tree_open = tree_view.is_visible()
        if tree_open then
          tree_api.tree.close()
        end
      end
      vim.cmd(command)
      if tree_api and tree_open then
        tree_api.tree.open()
        if switch_to_last then
          vim.cmd(lastwin..'wincmd w')
        end
      end
    end
  end

  -- close current buffer
  bindings.map.normal(
    '<A-w>',
    close_buffer('silent! bd', true)
  )
  -- close all buffers
  bindings.map.normal(
    '<A-W>',
    close_buffer('%bd | e# | bd#')
  )
end
registry.defer(buffer_management)
