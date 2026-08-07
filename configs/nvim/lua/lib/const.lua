-- common constants
api = vim.api
env = vim.env
fn = vim.fn
luv = vim.loop

plug_nvim_url = 'https://raw.githubusercontent.com/spywhere/plug.nvim/main/plug.lua'
config_home = fn.stdpath('config')
pack_site = fn.stdpath('data') .. '/site/pack'

lua_home = config_home .. '/lua'
plug_nvim_path = pack_site .. '/plug/opt/plug.nvim/lua/plug.lua'
-- Unused by the current backend: plug.backend.lazy is set up with no
-- options (lib/plugin-manager.lua), so lazy keeps its own root under
-- stdpath('data') and nothing ever writes here. Keep it anyway -- the
-- README demo's closing shot walks the LSP completion menu onto
-- plugin_home, so removing it changes what gets recorded
-- (supports/screenshot/dotfiles.tape).
plugin_home = config_home .. '/plugged'

prequire = function (...)
  local status, mod = pcall(require, ...)
  if status then
    return mod
  else
    return nil
  end
end
