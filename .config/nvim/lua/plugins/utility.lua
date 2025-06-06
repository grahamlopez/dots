return {

  --
  --      Syntax
  --

  -- https://github.com/nvim-treesitter/nvim-treesitter
  {
    --[[
    Without treesitter, using regex highlighting by default e.g. use :Inspect to
    see what is being used.

    The textobjects and refactor modules seem kinda cool, but have been really
    buggy for me, so they are disabled for now
    --]]
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      {
        -- https://github.com/nvim-treesitter/nvim-treesitter-context
        "nvim-treesitter/nvim-treesitter-context",

        -- TODO lazyvim's context is way better than mine
        -- and also consider https://github.com/SmiteshP/nvim-navic
      },
    },
    --  {
    --    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    --    "nvim-treesitter/nvim-treesitter-textobjects",
    --  },
    --  {
    --    -- https://github.com/nvim-treesitter/nvim-treesitter-refactor
    --    "nvim-treesitter/nvim-treesitter-refactor"
    --  },

    -- recommended YT vid for understanding treesitter
    -- https://www.youtube.com/watch?v=kYXcxJxJVxQ
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup({
        -- https://github.com/nvim-treesitter/nvim-treesitter/wiki/List-of-parsers
        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "fortran",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "rust",
          "vim",
          "vimdoc",
        },
        auto_install = true, -- for new filetypes not listed above
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          -- keymaps = { -- move these to be with the other keybindings (and improve them)
          --   init_selection = "<leader>ss",
          --   node_incremental = "<leader>si",
          --   scope_incremental = "<leader>sc",
          --   node_decremental = "<leader>sd",
          -- },
        },
      })
    end,
  },

  --
  --      Session Management
  --

  -- https://github.com/folke/persistence.nvim
  {
    -- Session management. This saves your session in the background,
    -- keeping track of open buffers, window arrangement, and more.
    -- You can restore sessions when returning through the dashboard.
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      branch = false,
      need = 2,
    },
    config = function() -- part of what's needed to preserve bufferline ordering
      require("persistence").setup({
        options = { "globals" }, -- include other options as needed
        pre_save = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
        end,
      })
    end,
  },

  --
  --      Clipboards and Registers
  --

  --
  --      Spelling
  --

}
