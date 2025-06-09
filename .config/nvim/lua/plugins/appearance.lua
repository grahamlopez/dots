return {

  --
  --      Theming
  --
  --      https://vimcolorschemes.com/i/top

  -- https://github.com/xiyaowong/transparent.nvim
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 900,
    config = function()
      -- vim.cmd.colorscheme("nightfox")
    end,
  },

  -- https://github.com/f-person/auto-dark-mode.nvim
  {
    -- neovim detects terminal background at startup, BUT
    -- doesn't work inside tmux
    -- doesn't affect already-running instances
    -- not needed anymore? https://github.com/vimpostor/vim-lumen?tab=readme-ov-file#is-this-plugin-still-needed-with-latest-vim
    -- this works, but TMUX doesn't propogate the DEC 2031 escape sequence to
    -- applications running inside of it
    -- but looks like there is a merged PR: https://github.com/tmux/tmux/pull/4353
    {
      "f-person/auto-dark-mode.nvim",
      opts = {
        set_dark_mode = function()
          vim.api.nvim_set_option_value("background", "dark", {})
          vim.cmd.colorscheme("tokyonight-moon")
        end,
        set_light_mode = function()
          vim.api.nvim_set_option_value("background", "light", {})
          vim.cmd.colorscheme("tokyonight-day")
        end,
        update_interval = 3000,
        fallback = "dark",
      },
    },
  },

  -- https://github.com/catppuccin/nvim
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    transparent = false,
    background = { -- :h background
      light = "latte",
      dark = "mocha",
    },
  },

  -- https://github.com/EdenEast/nightfox.nvim
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/nordtheme/vim
  -- TODO: maybe find a better nord theme implementation
  {
    "nordtheme/vim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/folke/tokyonight.nvim
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      light_style = "day",
      day_brightness = 0.3, -- 0 (dull) to 1 (virbrant)
      transparent = false,
    },
  },

  -- https://github.com/Mofiqul/dracula.nvim
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/shaunsingh/solarized.nvim
  -- FIXME: something might be wrong with this one
  {
    "shaunsingh/solarized.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/rebelot/kanagawa.nvim
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = false,
      background = { -- map the value of 'background' option to a theme
        dark = "wave", -- try "dragon" !
        light = "lotus",
      },
      -- remove the background of LineNr, {Sign,Fold}Column and friends
      colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
    },
  },

  --
  --      Statusline and bufferline appearance
  --

  -- https://github.com/nvim-lualine/lualine.nvim
  {
    "nvim-lualine/lualine.nvim", -- https://github.com/nvim-lualine/lualine.nvim
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- https://github.com/nvim-tree/nvim-web-devicons
      lazy = true,
      event = "VeryLazy",
    },

    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require("lualine").setup({
        options = {
          theme = "nord",
          globalstatus = true,
        },
        sections = {
          lualine_c = {
            "tabs",
            { "filename", path = 2 },
          },
        },
      })

      require("nvim-web-devicons").setup({ opts = {} })
    end,
  },

  -- https://github.com/akinsho/bufferline.nvim
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        numbers = "ordinal",
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(require("bufferline").nvim_bufferline)
          end)
        end,
      })
    end,
  },

  --
  --      Outline
  --

  -- https://github.com/hedyhli/outline.nvim
  {
    "hedyhli/outline.nvim",
    enabled = false,
    cmd = { "Outline", "OutlineOpen" },
    opts = {
      outline_window = {
        position = "right",
        width = 25,
        wrap = false,
        auto_close = false,
        auto_jump = false,
        jump_highlight_duration = 300,
      },
      outline_items = {
        show_symbol_details = true,
        show_symbol_lineno = false,
        highlight_hovered_item = true,
        auto_set_cursor = true,
      },
      symbols = {
        filter = {
          -- Remove some symbols for cleaner view
          "String",
          "Number",
          "Boolean",
          "Array",
          "Object",
          "Key",
          "Null",
        },
      },
      preview_window = {
        auto_preview = false,
        open_hover_on_preview = false,
        width = 50,
        min_width = 50,
        relative = "editor",
        border = "rounded",
      },
      guides = {
        enabled = true,
        markers = {
          bottom = "└",
          middle = "├",
          vertical = "│",
        },
      },
      keymaps = {
        close = { "<Esc>", "q" },
        goto_location = "<Cr>",
        peek_location = "o",
        goto_and_close = "<S-Cr>",
        restore_location = "<C-g>",
        hover_symbol = "<C-space>",
        toggle_preview = "K",
        rename_symbol = "r",
        code_actions = "a",
        fold = "h",
        unfold = "l",
        fold_all = "W",
        unfold_all = "E",
        fold_reset = "R",
      },
    },
  },

  -- https://github.com/stevearc/aerial.nvim
  {
    "stevearc/aerial.nvim",
    enabled = false,
    opts = {
      manage_folds = true,
      link_folds_to_tree = true,
      link_tree_to_folds = true,
    },
    -- Optional dependencies
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },

  --
  --      Zen/focus
  --

  -- https://github.com/folke/zen-mode.nvim
  {
    "folke/zen-mode.nvim",
    enabled = false,
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = {
        backdrop = 0.95,
        width = 120,
        height = 1,
        options = {
          signcolumn = "no",
          number = false,
          relativenumber = false,
          cursorline = false,
          cursorcolumn = false,
          foldcolumn = "0",
          list = false,
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        twilight = { enabled = true },
        gitsigns = { enabled = false },
        tmux = { enabled = false },
        kitty = {
          enabled = false,
          font = "+4",
        },
      },
    },
  },

  -- https://github.com/folke/twilight.nvim -- for dimming inactive code
  {
    "folke/twilight.nvim",
    enabled = false,
    opts = {
      dimming = {
        alpha = 0.25,
        color = { "Normal", "#ffffff" },
        term_bg = "#000000",
        inactive = false,
      },
      context = 10,
      treesitter = true,
      expand = {
        "function",
        "method",
        "table",
        "if_statement",
      },
      exclude = {},
    },
  },
}
