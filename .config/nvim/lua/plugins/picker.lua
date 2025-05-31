-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/telescope.lua
return {
  {
  "nvim-telescope/telescope.nvim", -- https://github.com/nvim-telescope/telescope.nvim
  tag = "0.1.5",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    -- useful site for unicode: https://symbl.cc/en/unicode/blocks/box-drawing/
    "nvim-telescope/telescope-symbols.nvim",
  },

  config = function()
    local actions = require("telescope.actions")
    require("telescope").setup {
      defaults = {
        layout_strategy = 'vertical',
        mappings = { -- https://github.com/nvim-telescope/telescope.nvim#default-mappings

          -- use '<C-/>' and '?' in insert and normal mode, respectively, to
          -- show the actions mapped to your picker

            i = {
                ["<C-d>"] = actions.results_scrolling_down,
                ["<C-u>"] = actions.results_scrolling_up,
                ["<C-f>"] = actions.preview_scrolling_down,
                ["<C-b>"] = actions.preview_scrolling_up,
            },
            n = {
                ["<C-d>"] = actions.results_scrolling_down,
                ["<C-u>"] = actions.results_scrolling_up,
                ["<C-f>"] = actions.preview_scrolling_down,
                ["<C-b>"] = actions.preview_scrolling_up,
            },

        },
        pickers = { -- https://github.com/nvim-telescope/telescope.nvim#pickers

        },
      },
    }
  end
  },
}


