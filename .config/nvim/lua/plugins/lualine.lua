-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/lualine.lua
-- https://github.com/nvim-lualine/lualine.nvim
local M = {
  "nvim-lualine/lualine.nvim",
  lazy = false,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
}

function M.config()
  require('lualine').setup {
    options = {
      theme = 'auto',
    },
    sections = {
      lualine_c = { 'buffers' },
    },
  }
end

return M
