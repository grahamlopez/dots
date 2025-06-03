-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/autocmds.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = function()
    -- set this to match line numbering?
    -- FIXME adapt to dark/light theme
    vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#121212" })
    vim.api.nvim_set_hl(0, "MatchParen", { ctermbg = "yellow", bg = "yellow" })
    vim.api.nvim_set_hl(0, "NormalFloat", { ctermbg = "NONE", bg = "NONE" })
  end,
})

-- Set environment variables for git when working on nvim config
local home = os.getenv("HOME")
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
  callback = function()
    if vim.fn.getcwd() == home .. "/.config/nvim" then
      vim.env.GIT_DIR = home .. "/.dots-git/"
      vim.env.GIT_WORK_TREE = home
    end
  end,
})

