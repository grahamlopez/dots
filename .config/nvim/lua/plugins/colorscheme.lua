
return {
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 900,
    config = function()
      vim.cmd.colorscheme("default")
    end,
  },
  {
    -- neovim detects terminal background at startup, BUT
    -- doesn't work inside tmux
    -- doesn't affect already-running instances
    { "f-person/auto-dark-mode.nvim", opts = {} }, -- https://github.com/f-person/auto-dark-mode.nvim
  },
}
