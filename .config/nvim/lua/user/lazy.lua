-- https://github.com/folke/lazy.nvim
-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/lazy.lua
--[[
    get lazy if it isn't already there
    .e.g try `:lua print(vim.fn.stdpath("data"))`
    and even `:lua print(vim.fn.stdpath "data" .. "/lazy/lazy.nvim")
--]]
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
-- now prepend it to the runtime path
vim.opt.rtp:prepend(lazypath)

--[[
    configure the lazy plugin manager itself. see
    https://github.com/folke/lazy.nvim#%EF%B8%8F-configuration
--]]
require("lazy").setup {
  spec = LAZY_PLUGIN_SPEC, -- in launch.lua; pass all specs in one global variable
  install = {
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { "tokyonight", "habamax" },
  },
  ui = {
    border = "rounded",
  },
  change_detection = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        "netrw",
        "netrwPlugin",
        -- "tarPlugin",
        "tohtml",
        "tutor",
        -- "zipPlugin",
      },
    },
  },
}
