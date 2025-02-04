-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/lualine.lua
-- https://github.com/nvim-lualine/lualine.nvim

return {
  "nvim-lualine/lualine.nvim", -- https://github.com/nvim-lualine/lualine.nvim
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- https://github.com/nvim-tree/nvim-web-devicons
    lazy = true,
    event = "VeryLazy",
  },

  config = function()

    require('lualine').setup {
      options = {
        theme = 'nord',
      },
      sections = {
        lualine_c = { 'buffers' },
      },
    }

    require('nvim-web-devicons').setup { opts = {} }

  end
}
