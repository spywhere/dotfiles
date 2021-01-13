let g:startify_files_number = 20
let g:startify_fortune_use_unicode = 1
let g:startify_enable_special = 0
let g:startify_custom_header = 'startify#center(startify#fortune#cowsay())'

lua <<EOF
function _G.GetIcons(path)
  local filename = vim.api.nvim_eval("fnamemodify('"..path.."', ':t')")
  local extension = vim.api.nvim_eval("fnamemodify('"..path.."', ':e')")
  local icon, hl_group = require'nvim-web-devicons'.get_icon(filename, extension, { default = true })
  if icon then
    return icon.." "
  else
    return ""
  end
end
EOF

function! StartifyEntryFormat()
  return 'v:lua.GetIcons(absolute_path) . " " . entry_path'
endfunction
