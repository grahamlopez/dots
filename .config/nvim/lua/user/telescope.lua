-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/telescope.lua
local M = {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5",
  dependencies = { "nvim-lua/plenary.nvim" },
  -- keys = { -- TODO this is for startup optimization and needs to be DRY'ed with whichkey.lua
  --   "<leader>bf",
  --   "<leader>fb",
  --   "<leader>ff",
  --   "<leader>fg",
  --   "<leader>fh",
  -- },
}

function M.config()
  require("telescope").setup {
    defaults = {
      layout_strategy = 'vertical',
      mappings = {
      },
    },
  }
end

return M
