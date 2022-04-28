-- common constants
api = vim.api
env = vim.env
fn = vim.fn
luv = vim.loop

plug_nvim_url = 'https://raw.githubusercontent.com/spywhere/plug.nvim/main/plug.lua'
config_home = fn.stdpath('config')

lua_home = config_home .. '/lua'
plug_nvim_path = lua_home .. '/plug.lua'
plugin_home = config_home .. '/plugged'

prequire = function (...)
  local status, mod = pcall(require, ...)
  if status then
    return mod
  else
    return nil
  end
end
