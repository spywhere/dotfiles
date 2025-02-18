local registry = require('lib.registry')
local bindings = require('lib.bindings')

local rtf = function ()
  bindings.cmd('CopyRTF', {
    function (args)
      require('rtf').copy_rtf({ args.line1, args.line2 })
    end,
    range = '%'
  })
end

if vim.fn.executable('textutil') == 1 and vim.fn.executable('pbcopy') then
  registry.defer(rtf)
end
