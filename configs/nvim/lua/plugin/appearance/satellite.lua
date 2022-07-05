local registry = require('lib.registry')

registry.install {
  'lewis6991/satellite.nvim',
  skip = registry.experiment('scroll').is_not('satellite'),
  options = {
    commit = '404b4d5'
  },
  lazy = true,
  config = function ()
    require('satellite').setup {
      current_only = true
    }
  end,
  delay = function ()
    local visible_duration = 3000;

    local timer = nil
    local show = function ()
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
