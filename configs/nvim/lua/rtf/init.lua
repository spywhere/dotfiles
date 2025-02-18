local M = {}

M.copy_rtf = function (range)
  local tohtml = prequire('tohtml')

  if not tohtml then
    print('[CopyRTF] Error: tohtml not found/enabled')
    return
  end

  local options = {
    text = true,
    stdin = tohtml.tohtml(nil, {
      range = range
    })
  }
  local response = vim.system({
    'textutil',
    '-convert',
    'rtf',
    '-stdin',
    '-stdout',
  }, options):wait()

  if response.code ~= 0 then
    print('[CopyRTF] Error: ' .. response.stderr)
    return
  end

  vim.system({
    'pbcopy',
  }, {
    stdin = response.stdout,
    text = true
  }):wait()
end

return M
