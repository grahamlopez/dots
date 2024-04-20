-- https://github.com/nvim-treesitter/nvim-treesitter
-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/treesitter.lua
--[[
    Without treesitter, using regex highlighting by default e.g. use :Inspect to
    see what is being used.

    The textobjects and refactor modules seem kinda cool, but have been really
    buggy for me, so
    they are disabled for now
--]]
local M = {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    {
      -- https://github.com/nvim-treesitter/nvim-treesitter-context
      "nvim-treesitter/nvim-treesitter-context",
      -- TODO lazyvim's context is way better than mine
      -- and also consider https://github.com/SmiteshP/nvim-navic
    }
  },
  --  {
  --    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  --    "nvim-treesitter/nvim-treesitter-textobjects",
  --  },
  --  {
  --    -- https://github.com/nvim-treesitter/nvim-treesitter-refactor
  --    "nvim-treesitter/nvim-treesitter-refactor"
  --  },
}

-- recommended YT vid for understanding treesitter
-- https://www.youtube.com/watch?v=kYXcxJxJVxQ
function M.config()
  ---@diagnostic disable-next-line: missing-fields
  require("nvim-treesitter.configs").setup({
    -- https://github.com/nvim-treesitter/nvim-treesitter/wiki/List-of-parsers
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "fortran",
      "haskell",
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
end

return M
