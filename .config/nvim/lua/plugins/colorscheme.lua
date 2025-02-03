-- other good themes
--
local M = {
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        -- transparent_background = true,
        transparent_background = vim.g.transparent_enabled,
        integrations = {
          nvimtree = { enabled = true, show_root = true, },
        },
      })
    end,
  },
  --[[
  {
    "dracula/vim",
    name = "dracula_vim",
  },
  {
    "mofiqul/dracula.nvim",
  },
  {
    "cocopon/iceberg.vim",
  },
  --]]
  {
    "rebelot/kanagawa.nvim",
  },
  --[[
  {
    "Tsuzat/NeoSolarized.nvim",
  },
  {
    "nordtheme/vim",
    name = "nord_vim",
  },
  --]]
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nightfox").setup({
        options = {
          -- transparent = true,
          transparent = vim.g.transparent_enabled,
        }
      })
      -- vim.cmd.colorscheme("nightfox")
    end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("tokyonight").setup({
        -- transparent = true,
        transparent = vim.g.transparent_enabled,
        sidebars = { "qf" },
      })
    end,
  },
  {
    "mofiqul/vscode.nvim",
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    -- dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.g.zenbones_compat = 1
    --     vim.g.zenbones_darken_comments = 45
    --     vim.cmd.colorscheme('zenbones')
    end
  },
  {
    -- TODO fix helpNote highlight group e.g. in :aerial-filetype-map
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 900,
    config = function()
      -- not needed anymore? I'm not sure why not
      -- require("transparent").setup {
      -- extra_groups = { -- define additional groups that should be clear
      --   'help',
      --   'Help',
      --   'helpKeyword',
      --   'helpHyperTextJump',
      --   'helpHyperTextEntry',
      --   'helpCommand',
      --   'helpHeader',
      --   'helpSectionDelim',
      --   'helpSectionDelim',
      --   'helpHyperTextEntry',
      --   'helpOption',
      --   'helpNote',
      --   'helpVim',
      --   'helpHyperTextEntry',
      --   'helpURL',
      --   'helpHyperTextEntry',
      --   'helpTag',
      --   'helpSpecial',
      --   'helpExample',
      --   'helpComment',
      --   --'helpTodo',
      --   'NormalFloat', -- plugins like Lazy, Mason, LspInfo
      -- },
      -- }
      -- require("transparent").clear_prefix("NvimTree")
      -- vim.cmd.TransparentDisable()
      vim.cmd.colorscheme("default")
    end,
  },
}

return M
