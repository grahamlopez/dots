-- https://github.com/nvim-tree/nvim-web-devicons
-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/devicons.lua
local M = {
  "nvim-tree/nvim-web-devicons",
  lazy = true,
  event = "VeryLazy",
}

function M.config()
  require "nvim-web-devicons"
end

return M
