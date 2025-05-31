
return {
  -- replaced by telescope-symbols.nvim
  -- "2KAbhishek/nerdy.nvim",
  -- config = function()
  --   require('telescope').load_extension('nerdy')
  -- end,

  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      branch = false,
      need = 2,
    },
    -- stylua: ignore
  },
}
