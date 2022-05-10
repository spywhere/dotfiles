local registry = require('lib.registry')

function tbl_reduce(tbl, fn, def)
  local output = def

  for k, v in ipairs(tbl) do
    output = fn(output, v, i, tbl)
  end

  return output
end

function boxed(generator)
  local utf8 = vim.o.encoding == 'utf-8'
  local top_left = utf8 and '╭' or '*'
  local top_right = utf8 and '╮' or '*'
  local bottom_left = utf8 and '╰' or '*'
  local bottom_right = utf8 and '╯' or '*'
  local hr = utf8 and '─' or '-'
  local vr = utf8 and '│' or '|'
  return function (max_width)
    max_width = max_width or 54
    local lines = generator(max_width - 2)

    if lines[1] == '' or lines[1] == ' ' then
      table.remove(lines, 1)
    end

    local box_size = math.max(
      max_width - 2,
      tbl_reduce(lines, function (max, line)
        return math.max(max, #line)
      end, 0)
    )
    lines = tbl_reduce(lines, function (new_lines, line)
      table.insert(new_lines, string.format(
        string.format('%%s%%%ss%%s', -box_size),
        vr,
        line,
        vr
      ))
      return new_lines
    end, {})

    table.insert(lines, 1, string.format(
      '%s%s%s',
      top_left,
      string.rep(hr, box_size),
      top_right
    ))

    table.insert(lines, string.format(
      '%s%s%s',
      bottom_left,
      string.rep(hr, box_size),
      bottom_right
    ))

    return lines
  end
end

function cowsay(generator)
  return function (max_width)
    max_width = max_width or 54
    return vim.list_extend(boxed(generator)(max_width), {
      '       o',
      '        o   ^__^',
      '         o  (oo)\\_______',
      '            (__)\\       )\\/\\',
      '                ||----w |',
      '                ||     ||',
    })
  end
end

registry.install {
  'goolord/alpha-nvim',
  skip = registry.experiment('startify').on,
  post_install = function ()
    vim.defer_fn(function ()
      vim.cmd('Alpha')
    end, 10)
    vim.defer_fn(function ()
      vim.cmd('IndentBlanklineDisable')
    end, 100)
  end,
  config = function ()
    local startify = require('alpha.themes.startify')

    local header = {
      type = 'text',
      val = cowsay(require('alpha.fortune'))(
        nil, startify.config.opts.margin
      ),
      opts = {
        hl = "Type",
        shrink_margin = false,
        position = 'center',
        width = 54
      }
    }

    local function mru_title(cwd)
      if cwd == nil then
        return 'MRU'
      else
        return function () return mru_title() .. ' ' .. fn.getcwd() end
      end
    end

    local function mru(start, cwd)
      return {
        type = 'group',
        val = {
          { type = 'padding', val = 1 },
          { type = 'text', val = mru_title(cwd), opts = { hl = 'SpecialComment' } },
          { type = 'padding', val = 1 },
          { type = 'group', val = function ()
            return { startify.mru(start, cwd, 20) }
          end }
        }
      }
    end

    startify.config.layout = {
      { type = 'padding', val = 1 },
      header,
      { type = 'padding', val = 2 },
      startify.section.top_buttons,
      mru(1, fn.getcwd()),
      mru(21),
      { type = 'padding', val = 1 },
      startify.section.bottom_buttons,
      startify.section.footer
    }

    require('alpha').setup(startify.config)
  end
}
