-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/telescope.lua
return {
  "nvim-telescope/telescope.nvim", -- https://github.com/nvim-telescope/telescope.nvim
  tag = "0.1.5",
  dependencies = { "nvim-lua/plenary.nvim" }, -- required

  config = function()
    require("telescope").setup {
      defaults = {
        layout_strategy = 'vertical',
        mappings = { -- https://github.com/nvim-telescope/telescope.nvim#default-mappings

          -- use '<C-/>' and '?' in insert and normal mode, respectively, to
          -- show the actions mapped to your picker

        },
        pickers = { -- https://github.com/nvim-telescope/telescope.nvim#pickers

        },
      },
    }
  end
}


