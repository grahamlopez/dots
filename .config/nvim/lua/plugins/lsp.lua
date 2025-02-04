-- some ideas from 
-- https://github.com/tjdevries/config.nvim/blob/master/lua/custom/plugins/lsp.lua
--   other plugins in TJ's config:
--   - https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
--   - https://github.com/b0o/SchemaStore.nvim
--   - https://git.sr.ht/~whynothugo/lsp_lines.nvim
--   - https://github.com/stevearc/conform.nvim
--   - https://github.com/folke/lazydev.nvim

return {
  "neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
  dependencies = {

    "williamboman/mason.nvim", -- https://github.com/williamboman/mason.nvim
    "williamboman/mason-lspconfig.nvim", -- https://github.com/williamboman/mason-lspconfig.nvim

    { "j-hui/fidget.nvim", opts = {} } -- https://github.com/j-hui/fidget.nvim

  },

  config = function()

    local lspconfig = require("lspconfig")

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
      ensure_installed = {
      -- "bashls",
      -- "clangd",
      -- "clang-format",
      "lua_ls",
      -- "marksman",
      }
    }

  end
}
