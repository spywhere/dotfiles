local registry = require('lib.registry')

registry.install {
  'lewis6991/satellite.nvim',
  options = fn.has('nvim-0.8') == 0 and {
    commit = '404b4d5'
  } or nil,
  lazy = true,
  config = function ()
    require('satellite').setup {
      current_only = true,
      handlers = {
        marks = {
          enable = false
        }
      }
    }
  end,
  delay = function ()
    local visible_duration = 3000;

    local timer = nil
    local show = function ()
      if vim.bo.buftype ~= '' and vim.bo.buftype ~= 'terminal' and vim.fn.win_gettype() ~= '' then
        return
      end
      vim.cmd('SatelliteEnable')

      if timer then
        luv.timer_stop(timer)
        timer = nil
      end
      timer = vim.defer_fn(function ()
        vim.cmd('SatelliteDisable')
      end, visible_duration)
    end

    registry.auto(
      {
        'WinEnter', 'BufEnter', 'BufWinEnter', 'FocusGained', 'CursorMoved',
        'WinScrolled', 'VimResized'
      },
      show
    )
    registry.auto(
      {
        'WinLeave', 'BufLeave', 'BufWinLeave', 'FocusLost', 'QuitPre'
      },
      function ()
        vim.cmd('SatelliteDisable')
      end
    )
  end
}
