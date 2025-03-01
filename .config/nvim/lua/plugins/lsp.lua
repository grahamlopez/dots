-- some ideas from 
-- https://github.com/tjdevries/config.nvim/blob/master/lua/custom/plugins/lsp.lua
--   other plugins in TJ's config:
--   - https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
--   - https://github.com/b0o/SchemaStore.nvim - only for JS kinda stuff
--   - https://git.sr.ht/~whynothugo/lsp_lines.nvim
--   - https://github.com/stevearc/conform.nvim
--
--   use ':echo executable("lua-language-server")' etc. to make sure neovim can
--   find and execute the various language servers

return {
  "neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
  dependencies = {

    "williamboman/mason.nvim", -- https://github.com/williamboman/mason.nvim
    "williamboman/mason-lspconfig.nvim", -- https://github.com/williamboman/mason-lspconfig.nvim
    "WhoIsSethDaniel/mason-tool-installer.nvim", -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
    {
      -- removes need for e.g. lua_ls.setup ({ diagnostics = { globals = { "vim" } } })
      "folke/lazydev.nvim", -- https://github.com/folke/lazydev.nvim
      ft = "lua", -- only load on lua files
      opts = {
        library = {
           -- See the configuration section for more details
           -- Load luvit types when the `vim.uv` word is found
           { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },

    { "j-hui/fidget.nvim", opts = {} } -- https://github.com/j-hui/fidget.nvim

  },

  config = function()

    local server_list = {
      -- "bashls", -- requires npm
      "clangd",
      "clang-format",
      "lua_ls",
      "tectonic",
      -- "marksman",
    }

    -- plugin setup order recommended by
    -- https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#setup

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

    ---@diagnostic disable-next-line: missing-fields
    require("mason-lspconfig").setup({})

    require("mason-tool-installer").setup({
      ensure_installed = server_list,
    })

    require("lspconfig").clangd.setup({})

    -- https://luals.github.io/wiki/configuration/
    require("lspconfig").lua_ls.setup({})

  end
}
