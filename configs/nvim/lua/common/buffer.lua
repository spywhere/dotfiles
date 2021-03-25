local M = {}

M.smart_name = function ()
  local dirsep = package.config:sub(1, 1)
  local smart_buffers = {}
  local buffer_count_per_tail = {}

  local current_index = fn.bufnr()

  function to_smart_buffer(index)
    local name = fn.bufname(index)

    local smart_buffer = {}
    if name:len() > 0 then
      smart_buffer.path = fn.fnamemodify(name, ':p:~:.')
      smart_buffer.sep = fn.strridx(smart_buffer.path, dirsep, smart_buffer.path:len() - 2)
      smart_buffer.label = smart_buffer.path:sub(smart_buffer.sep + 2, smart_buffer.path:len())
      buffer_count_per_tail[smart_buffer.label] = (buffer_count_per_tail[smart_buffer.label] or 0) + 1
    else
      smart_buffer.path = name
      smart_buffer.label = name
    end

    return smart_buffer
  end

  for index=1,fn.bufnr('$') do
    smart_buffers[index] = to_smart_buffer(index)
  end

  local current_label = smart_buffers[current_index].label
  if not buffer_count_per_tail[current_label] or buffer_count_per_tail[current_label] < 2 then
    return current_label
  end

  while buffer_count_per_tail[smart_buffers[current_index].label] > 1 do
    local ambiguous = buffer_count_per_tail
    buffer_count_per_tail = {}

    local smart_buffer
    for _, smart_buffer in pairs(smart_buffers) do
      if smart_buffer.path:len() > 0 then
        if smart_buffer.sep ~= -1 and  vim.tbl_contains(vim.tbl_keys(ambiguous), smart_buffer.label) then
          smart_buffer.sep = fn.strridx(smart_buffer.path, dirsep, smart_buffer.sep - 1)
          smart_buffer.label = smart_buffer.path:sub(smart_buffer.sep + 2, smart_buffer.path:len())
        end
        buffer_count_per_tail[smart_buffer.label] = (buffer_count_per_tail[smart_buffer.label] or 0) + 1
      end
    end
  end

  return fn.pathshorten(smart_buffers[current_index].label)
end

return M
