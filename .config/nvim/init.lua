-- Set <space> as the leader key
-- See `:help mapleader`
-- Ensure this happens before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Neovim 0.11 performance optimizations
vim.loader.enable() -- Enable faster Lua module loading

-- Bootstrap lazy.nvim
-- https://github.com/folke/lazy.nvim
--[[
    get lazy if it isn't already there
    .e.g try `:lua print(vim.fn.stdpath("data"))`
    and even `:lua print(vim.fn.stdpath "data" .. "/lazy/lazy.nvim")
--]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- ---@diagnostic disable-next-line: undefined-field
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

-- Configure lazy.nvim with performance optimizations
require("lazy").setup({
  import = "plugins", -- use 'enabled = false' if needed
  ui = {
    border = "rounded",
  },
  change_detection = {
    enabled = false, -- Better performance
    notify = false,
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to improve startup time
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrw",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- Load configuration modules
-- These could also go in 'plugin/' like teejdv.
-- Not sure about which of these options is best for ordering, etc.
require("settings.options")
require("settings.autocmds")
require("settings.keymaps")
-- RFE: would like to have a portable and easy encryption workflow
-- toggle command to convert the current file to encrypted/decrypted by default
-- automatically decrypt file on opening; encrypt on closing

-- Enable native diagnostic improvements
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    source = "if_many",
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    ---@diagnostic disable-next-line: assign-type-mismatch
    source = "always",
  },
})

--[[
Folding plugin idea: FIXME: move this to the nvim notes file

What I want is to use manual open/close commands as normal. Then, if a fold
needs to open automatically because the cursor moves into the region, that fold
should close when the cursor leaves, but only if it was opened automatically as
a result of the movement. Manually opened folds should remain open.

What Would Be Required

To achieve your desired behavior, you would need:
    A mechanism to track which folds were auto-opened (e.g., by search or cursor movement).
    Logic to close only those folds when the cursor leaves, leaving manually opened folds untouched.

This would require a custom Lua plugin that:
    Hooks into cursor movement and search events.
    Maintains a data structure tracking which folds were opened automatically.
    Closes only those folds when the cursor leaves their range.
--]]
