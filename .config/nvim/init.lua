
-- Set <space> as the leader key
-- See `:help mapleader`
-- Ensure this happens before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- https://github.com/folke/lazy.nvim
--[[
    get lazy if it isn't already there
    .e.g try `:lua print(vim.fn.stdpath("data"))`
    and even `:lua print(vim.fn.stdpath "data" .. "/lazy/lazy.nvim")
--]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
-- now prepend it to the runtime path
vim.opt.rtp:prepend(lazypath)

--[[
    configure the lazy plugin manager itself. see
    https://lazy.folke.io/configuration
--]]
require("lazy").setup({
  import = "plugins", -- use 'enabled = false' if needed
  ui = {
    border = "rounded",
  },
  change_detection = {
    enabled = false,
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
})

-- workaround for nvim 0.10.3 when using :Inspect
vim.hl = vim.highlight

-- These could also go in 'plugin/' like teejdv.
-- Not sure about which of these options is best for ordering, etc.
require("settings.options")
require("settings.autocmds")
require("settings.keymaps")

