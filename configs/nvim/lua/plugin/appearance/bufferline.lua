local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'akinsho/nvim-bufferline.lua',
  delay = function ()
    local is_gui = fn.exists('g:GuiLoaded') == 1
    require('bufferline').setup({
      options = {
        diagnostics = false,
        always_show_bufferline = false,
        show_close_icon = false,
        show_buffer_close_icons = is_gui,
        indicator_icon = ' ',
        separator_style = { '', '' },
        offsets = {
          {
            filetype = "NvimTree",
            text = "Explorer",
            highlight = "Directory",
            text_align = "center"
          }
        },
        custom_filter = function (bufno)
          return vim.bo[bufno].filetype ~= 'help' and vim.bo[bufno].filetype ~= 'qf'
        end
      }
    })

    -- workaround to fix tabline from showing during start up with startify
    local hide_tabline = function ()
      local total_buffers = vim.tbl_count(fn.getbufinfo({ buflisted = 1 }))
      if total_buffers > 1 then
        return
      end

      bindings.set('showtabline', 0)
    end
    vim.defer_fn(hide_tabline, 0)
  end
}
