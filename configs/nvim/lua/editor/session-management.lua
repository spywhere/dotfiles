local bindings = require('lib/bindings')
local registry = require('lib/registry')
local logger = require('lib/logger')

local session_commands = function ()
  local load_session = {
    function(_, path)
      local session_file = path or 'Session.vim'
      if fn.filereadable(session_file) == 1 then
        api.nvim_command(table.concat({ 'source', session_file }, ' '))
      else
        logger.inline.info(string.format('No session file found (%s)', session_file))
      end
    end,
    '-nargs=*'
  }
  bindings.cmd('LoadSession', load_session)
end
registry.defer_first(session_commands)
