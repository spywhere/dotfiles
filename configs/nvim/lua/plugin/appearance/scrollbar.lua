local registry = require('lib/registry')

registry.install {
  'Xuyuanp/scrollbar.nvim',
  lazy = true,
  config = function ()
    vim.g.scrollbar_right_offset = 0
    vim.g.scrollbar_shape = {
      head = '▎',
      body = '▎',
      tail = '▎'
    }
    vim.g.scrollbar_excluded_filetypes = {
      'nvimtree',
      'startify'
    }
  end,
  defer = function ()
    local visible_duration = 3000;

    local timer = nil
    local show = function ()
      require('scrollbar').show()

      if timer then
        luv.timer_stop(timer)
        timer = nil
      end
      timer = vim.defer_fn(require('scrollbar').clear, visible_duration)
    end

    registry.auto(
      {
        'WinEnter', 'BufEnter', 'BufWinEnter', 'FocusGained', 'CursorMoved',
        'VimResized'
      },
      show
    )
    registry.auto(
      {
        'WinLeave', 'BufLeave', 'BufWinLeave', 'FocusLost', 'QuitPre'
      },
      require('scrollbar').clear
    )
  end
}
