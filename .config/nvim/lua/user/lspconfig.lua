-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/lspconfig.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/keymaps.lua
--[[
    Here's the manual way to set up a language server without any plugins

-- need to wrap it in an autocmd because the language server starts too quickly,
-- so kick it upon bufentry

vim.api.nvim_create_autocmd("BufEnter", {
  -- probably want a pattern here
  callback = function()
    vim.lsp.start({
      name = "clangd",
      cmd = {"/home/graham/.local/share/grahamvim/mason/bin/clangd"},
      root_dir = vim.fn.getcwd(),
    })
  end,
})
--]]

-- https://github.com/neovim/nvim-lspconfig
local M = {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
}

function M.config()
  local lspconfig = require("lspconfig")
  lspconfig.bashls.setup({})
  lspconfig.clangd.setup({})
  -- https://luals.github.io/wiki/configuration/
  lspconfig.lua_ls.setup({
    settings = {
      Lua = {
        format = {
          enable = true,
        },
        diagnostics = {
          globals = { "vim", "spec" }, -- be aware of our global function
        },
        runtime = {
          version = "LuaJIT",
          special = {
            spec = "require", -- clever!
          },
        },
      },
    },
  })
end

return M
