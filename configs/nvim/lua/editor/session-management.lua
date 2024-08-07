local bindings = require('lib.bindings')
local registry = require('lib.registry')
local logger = require('lib.logger')

local session_opts = function ()
  vim.opt.sessionoptions:remove { 'folds' }
end
registry.pre(session_opts)

local session_commands = function ()
  local load_session = {
    function(opts)
      local path = opts.args
      local session_file = path ~= '' and path or 'Session.vim'
      if fn.filereadable(session_file) == 1 then
        vim.cmd(table.concat({ 'source', session_file }, ' '))
      else
        logger.inline.info(string.format('No session file found (%s)', session_file))
      end
    end,
    nargs='*'
  }
  bindings.cmd('LoadSession', load_session)
end
registry.defer_first(session_commands)
