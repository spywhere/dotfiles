local M = {
  darkgray = { gui='#1c1c1c', cterm=234, gui_transparent='none' }
}

-- color palettes (from nord-vim)
-- #2e3440 237  nord0 bg
-- #3b4252 238  nord1
-- #434c5e 239  nord2
-- #4c566a 240  nord3
-- #d8dee9 188  nord4 fg
-- #e5e9f0 255  nord5
-- #eceff4 255  nord6

-- #8fbcbb 109  nord7
-- #88c0d0 110  nord8
-- #81a1c1 109  nord9
-- #5e81ac  67  nord10
-- #bf616a 131  nord11
-- #d08770 173  nord12
-- #ebcb8b 222  nord13
-- #a3be8c 144  nord14
-- #b48ead 139  nord15
--
-- #616e88  60  nord3-bright
-- #5c6370 241  line-gray
-- #2c323c  23  cursor-gray
-- #3b4048 238  special-gray
M.nord = {
  orange = { gui='#d08770', cterm=173 },
  lightblue = { gui='#5e81ac', cterm=67 },

  black = { gui='#3b4252', cterm=238 },
  red = { gui='#bf616a', cterm=131 },
  green = { gui='#a3be8c', cterm=144 },
  yellow = { gui='#ebcb8b', cterm=222 },
  blue = { gui='#81a1c1', cterm=109 },
  magenta = { gui='#b48ead', cterm=139 },
  cyan = { gui='#88c0d0', cterm=110 },
  white = { gui='#e5e9f0', cterm=255 },

  brightblack = { gui='#4c566a', cterm=240 },
  brightred = 'red',
  brightgreen = 'green',
  brightyellow = 'yellow',
  brightblue = 'blue',
  brightmagenta = 'magenta',
  brightcyan = { gui='#8fbcbb', cterm=109 },
  brightwhite = { gui='#eceff4', cterm=255 },

  dimblack = { gui='#373e4d' },
  dimred = { gui='#94545d' },
  dimgreen = { gui='#809575' },
  dimyellow = { gui='#b29e75' },
  dimblue = { gui='#68809a' },
  dimmagenta = { gui='#8c738c' },
  dimcyan = { gui='#6d96a6' },
  dimwhite = { gui='#aeb5bb' }
}

M.resolve_color = function (name, palette)
  local definitions = palette or M.nord
  if not definitions[name] then
    return { gui='NONE', cterm='NONE' }
  end
  local color = definitions[name]
  if type(color) == 'string' then
    return M.resolve_color(color)
  end
  return color
end

M.group = function (fg, bg, palette)
  local definitions = palette or M.nord
  local group = {}

  if type(fg) == 'string' and definitions[fg] then
    local color = M.resolve_color(fg, palette)
    group.fg=color.gui
    group.ctermfg=color.cterm
  end
  if type(bg) == 'string' and definitions[bg] then
    local color = M.resolve_color(bg, palette)
    group.bg=color.gui
    group.ctermbg=color.cterm
  end
  return group
end

return M
