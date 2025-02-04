-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/nvimtree.lua
local M = {
  "nvim-tree/nvim-tree.lua",
  event = "VeryLazy",
}

function M.config()
  require("nvim-tree").setup({
  })
end

return M
