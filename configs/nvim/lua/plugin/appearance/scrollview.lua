local registry = require('lib.registry')

registry.install {
  'dstein64/nvim-scrollview',
  skip = registry.experiment('scrollview').off,
  lazy = true,
  config = function ()
    vim.g.scrollview_column = 1
    vim.g.scrollview_character = '▎'
    vim.g.scrollview_excluded_filetypes = {
      'nvimtree',
      'startify'
    }
  end,
  defer = function ()
    local scrollview = prequire('scrollview')
    if not scrollview then
      return
    end
    local visible_duration = 3000;

    local timer = nil
    local show = function ()
      local scrollview = prequire('scrollview')
      if not scrollview then
	      return
      end
      scrollview.scrollview_enable()

      if timer then
        luv.timer_stop(timer)
        timer = nil
      end
      timer = vim.defer_fn(scrollview.scrollview_disable, visible_duration)
    end

    registry.auto(
      {
        'WinEnter', 'BufEnter', 'BufWinEnter', 'FocusGained', 'WinScrolled',
        'VimResized'
      },
      show
    )
    registry.auto(
      {
        'WinLeave', 'BufLeave', 'BufWinLeave', 'FocusLost', 'QuitPre'
      },
      function ()
        local scrollview = prequire('scrollview')
        if not scrollview then
          return
        end
        scrollview.scrollview_disable()
      end
    )
  end
}