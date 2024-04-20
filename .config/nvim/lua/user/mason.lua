-- for installing binaries for e.g. language servers, formatters, linters, etc.
-- just install them and put them in our path
-- see the package registry at https://github.com/mason-org/mason-registry/tree/main/packages
-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/mason.lua
local M = {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
  },
}


function M.config()
  local servers = {
    -- "bashls",
    "lua_ls",
    -- "marksman",
  }

  require("mason").setup {
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      },
    },
  }

  require("mason-lspconfig").setup {
    ensure_installed = servers,
  }
end

return M
