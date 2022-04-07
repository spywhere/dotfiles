local bindings = require('lib.bindings')
local registry = require('lib.registry')

local split_management = function ()
  -- split resize
  bindings.map.normal('<A-S-Left>', '<cmd>vertical resize -5<cr>')
  bindings.map.normal('<A-S-Right>', '<cmd>vertical resize +5<cr>')
  bindings.map.normal('<A-S-Up>', '<cmd>resize -5<cr>')
  bindings.map.normal('<A-S-Down>', '<cmd>resize +5<cr>')
  bindings.map.normal('<Left>', '<cmd>vertical resize -1<cr>')
  bindings.map.normal('<Right>', '<cmd>vertical resize +1<cr>')
  bindings.map.normal('<Up>', '<cmd>resize -1<cr>')
  bindings.map.normal('<Down>', '<cmd>resize +1<cr>')

  -- quick split
  bindings.map.normal('<leader><Left>', '<cmd>topleft vnew<cr>')
  bindings.map.normal('<leader><Right>', '<cmd>botright vnew<cr>')
  bindings.map.normal('<leader><Up>', '<cmd>topleft new<cr>')
  bindings.map.normal('<leader><Down>', '<cmd>botright new<cr>')
  bindings.map.normal('<leader><Up><Left>', '<cmd>leftabove vnew<cr>')
  bindings.map.normal('<leader><Up><Right>', '<cmd>rightbelow vnew<cr>')
  bindings.map.normal('<leader><Down><Left>', '<cmd>rightbelow new<cr>')
  bindings.map.normal('<leader><Down><Right>', '<cmd>leftabove new<cr>')
end
registry.defer(split_management)

local buffer_management = function ()
  -- switch buffer
  bindings.map.normal('<A-Left>', '<cmd>bprev<cr>')
  bindings.map.normal('<A-Right>', '<cmd>bnext<cr>')

  local close_buffer = function (command, on_tree_open)
    return function ()
      if string.lower(vim.bo.filetype) == 'nvimtree' then
        return
      end

      -- only one buffer left
      if #fn.getbufinfo({ buflisted = 1 }) == 1 then
        return
      end

      local tree_open = false
      local tree = prequire('nvim-tree')
      if tree then
        local tree_view = require('nvim-tree.view')
        tree_open = tree_view.is_visible()
        if tree_open then
          tree_view.close()
        end
      end
      vim.cmd(command)
      if tree and tree_open then
        tree.open()
        if on_tree_open and on_tree_open ~= "" then
          vim.cmd(on_tree_open)
        end
      end
    end
  end

  -- close current buffer
  bindings.map.normal(
    '<A-w>',
    close_buffer('silent! bd')
  )
  -- close all buffers
  bindings.map.normal(
    '<A-W>',
    close_buffer('%bd | e# | bd#')
  )
end
registry.defer(buffer_management)
