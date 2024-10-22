local P = {
  bufid = nil,
  winid = nil
}
local M = {}

local to_int = function (frac, value)
  if frac >= 1 then
    return math.min(frac, value)
  end

  return math.floor(math.max(0, frac) * value)
end

P.layout = function (opts, winid)
  local winopts = opts.winopts or {}
  winopts.relative = 'editor'
  winopts.style = 'minimal'
  winopts.width = to_int(opts.width or 0.9, vim.o.columns)
  winopts.height = to_int(opts.height or 0.9, vim.o.lines)
  winopts.col = math.floor(vim.o.columns / 2 - winopts.width / 2)
  winopts.row = math.floor(vim.o.lines / 2 - winopts.height / 2)
  winopts.title = string.format(' %s ', 'ChatGPT')
  winopts.title_pos = 'center'
  winopts.border = 'rounded'

  if winid then
    vim.api.nvim_win_set_config(winid, winopts)
  else
    return winopts
  end
end

M.create = function (options)
  local opts = options or {}
  local cmd = { 'gpt' }
  table.insert(cmd, '-c')
  local prompt = opts.prompt or {}
  if prompt.system and prompt.system ~= '' then
    table.insert(cmd, prompt.system)
  end

  P.bufid = vim.api.nvim_create_buf(false, true)
  vim.bo[P.bufid].bufhidden = 'wipe'
  vim.bo[P.bufid].modifiable = true
  vim.api.nvim_buf_call(P.bufid, function ()
    vim.fn.termopen(cmd, {
      cwd = vim.fn.getcwd(-1, -1),
      on_exit = function ()
        vim.api.nvim_win_close(P.winid, true)
      end
    })
  end)
  vim.api.nvim_create_autocmd('VimResized', {
    buffer = P.bufid,
    callback = function ()
      vim.api.nvim_win_set_config(P.winid, P.layout(opts, P.winid))
    end
  })
  vim.api.nvim_create_autocmd('TermLeave', {
    buffer = P.bufid,
    callback = function ()
      vim.api.nvim_buf_call(P.bufid, function ()
        vim.cmd('startinsert!')
      end)
    end
  })
  -- TODO
  --   Keymap to scroll up/down

  P.winid = vim.api.nvim_open_win(P.bufid, true, P.layout(opts))
end

M.fzf = function (options)
  local opts = options or {}
  require('fzf-lua').fzf_exec('find . -maxdepth 1 -type f', {
    prompt = opts.prompt or "GPT Context> ",
    fn_transform = function (line)
      local last = function (list)
        return list[#list]
      end
      return last(vim.split(line, '/'))
    end,
    cwd = vim.env.CLIGPT_CONTEXT_STORAGE,
    previewer = false,
    preview = {
      type = "cmd",
      fn = function (items)
        local file = require('fzf-lua').path.entry_to_file(items[1])
        return string.format("CLIGPT_FORCE_COLOR=1 gpt --parse=%s", file.path)
      end
    },
    actions = {
      ['default'] = function (selected, action_opts)
        print('selected item:', selected[1] or action_opts.last_query)
      end
    }
  })
end

return M
