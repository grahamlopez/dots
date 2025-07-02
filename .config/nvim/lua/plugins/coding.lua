return {

  --
  --      Code Formatting
  --

  -- https://github.com/stevearc/conform.nvim
  {
    "stevearc/conform.nvim",
    enabled = true,
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        bash = { "shfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        javascript = { "prettier" },
        json = { "prettier" },
        latex = { "latexindent" },
        lua = { "stylua" },
        markdown = { "prettier", "markdownlint" },
        python = { "isort", "black" },
        sh = { "shfmt" },
        tex = { "latexindent" },
        typescript = { "prettier" },
        yaml = { "prettier" },
      },
      -- here is a pretty long comment line that is not getting formatted when it goes too long
      -- formatters = {
      --   prettier = {
      --     args = { "--print-width=80 --prose-wrap=always" },
      --   },
      -- },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = function(bufnr)
        -- Enable with a global or buffer-local variable
        if not vim.g.enable_autoformat and not vim.b[bufnr].enable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
    init = function()
      -- If you want the formatexpr, here is the place to set it
      -- this breaks 'gq' linewrapping
      -- Here is the current state:
      --    - 'gq'  runs formatexpr=v:lua.vim.lsp.formatexpr()
      --    - 'gw'  ignores formatexpr and formatprg
      --    - '_lf' runs conform.format()
      --    - autoformat on save runs conform.format()
      -- vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },

  --
  --      Git
  --

  -- https://github.com/lewis6991/gitsigns.nvim
  -- TODO: stage hunks and commit, see in-buffer diffs
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "\\" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "⍀" },
        untracked = { text = "▎" },
      },
      numhl = true,
    },
  },

  --
  --      TODO/FIXME
  --

  -- Highlight and search for TODO, FIXME, etc. comments
  -- https://github.com/folke/todo-comments.nvim
  {
    "folke/todo-comments.nvim",
    enabled = true,
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      keywords = {
        -- FIXME, FIXME, BUG, FIXIT, ISSUE
        -- HACK
        -- WARN, WARNING, XXX
        -- PERF, OPTIM, PERFORMANCE, OPTIMIZE
        -- NOTE, INFO
        -- TEST, TESTING, PASSED, FAILED
        TODO = { icon = " ", color = "info", alt = { "NEXT" } },
        IDEA = { icon = "󰛨 ", color = "hint", alt = { "RFE" } },
        UPSTREAM = { icon = " ", color = "info" },
        QUESTION = { icon = " ", color = "warning" },
      },
      merge_keywords = true,
      -- to get just underlining the keyword need: gui_style, highlight.keyword, highlight.after
      -- gui_style = {
      --   fg = "underline",
      --   bg = "none",
      -- },
      highlight = {
        comments_only = false,
        -- keyword = "fg", -- wide_bg or fg
        -- after = "",
        pattern = [[.*<(KEYWORDS):]], -- customize this pattern as needed
      },
      pattern = [[\b(KEYWORDS):]], -- ripgrep regex
    },
  },

  --
  --      Debugging
  --

  -- Enhanced diagnostics display
  -- https://github.com/folke/trouble.nvim
  {
    "folke/trouble.nvim",
    enabled = false,
    cmd = { "Trouble" },
    opts = {
      use_diagnostic_signs = true,
    },
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  --
  --      Commenting, brackets, etc.
  --

  -- https://github.com/numToStr/Comment.nvim
  {
    "numToStr/Comment.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("Comment").setup({
        pre_hook = require(
          "ts_context_commentstring.integrations.comment_nvim"
        ).create_pre_hook(),
      })
    end,
  },

  -- Auto-pairs for brackets
  -- https://github.com/windwp/nvim-autopairs
  {
    "windwp/nvim-autopairs",
    enabled = false,
    event = "InsertEnter",
    opts = {},
    config = function(_, opts)
      require("nvim-autopairs").setup(opts)
      -- Integration with cmp
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- Surround motions
  -- https://github.com/kylechui/nvim-surround
  {
    "kylechui/nvim-surround",
    enabled = false,
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },

  --
  --      LSP
  --

  -- Key enhancements for Neovim 0.11:
  --
  -- 1. **Native LSP Configuration**: Uses Neovim 0.11's new `vim.lsp.config` API instead of lspconfig
  -- 2. **Language Support**: Full setup for C/C++, Lua, Bash, LaTeX, and Markdown
  -- 3. **Auto-formatting**: Conform.nvim with language-specific formatters
  -- 4. **Enhanced Completion**: nvim-cmp with multiple sources and snippet support
  -- 5. **Better Diagnostics**: Trouble.nvim for enhanced error display
  -- 6. **Git Integration**: Comprehensive gitsigns configuration
  -- 7. **Performance**: Optimized loading and configuration

  -- Neovim 0.11 Native LSP Configuration
  -- We no longer need nvim-lspconfig or mason for basic setup
  -- (but are keeping them around for transitioning purposes)
  -- https://github.com/neovim/nvim-lspconfig
  -- https://github.com/williamboman/mason.nvim
  -- https://github.com/williamboman/mason-lspconfig.nvim
  -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
  {
    "neovim/nvim-lspconfig",
    -- event = "VeryLazy", -- lazy loading causes problems with mason
    -- automatically installing tools below
    dependencies = {
      -- Mason for easy LSP installation (optional but convenient)
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- Mason setup for easy server installation
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      -- IDEA: it would be nice to remove tools/dependencies on npm
      -- Install language servers and tools
      local servers = {
        -- Language servers
        "lua_ls",
        "clangd",
        "bashls",
        "texlab", -- LaTeX
        "marksman", -- Markdown
      }
      local tools = {
        -- Formatters
        "stylua",
        "clang-format",
        "shfmt",
        "prettier",
        "markdownlint",
        "latexindent",
      }

      ---@diagnostic disable-next-line: missing-fields
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        -- automatic_enable = false,
      })

      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(servers), tools),
        -- auto_update = false,
        -- run_on_start = true,
      })

      -- Neovim 0.11 native LSP configurations
      -- These replace the need for complex lspconfig setups

      -- Lua Language Server
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = {
          ".luarc.json",
          ".luarc.jsonc",
          ".luacheckrc",
          ".stylua.toml",
          "stylua.toml",
          "selene.toml",
          "selene.yml",
          ".git",
        },
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
            },
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }

      -- C/C++ Language Server (clangd)
      vim.lsp.config.clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        root_markers = {
          ".clangd",
          ".clang-tidy",
          ".clang-format",
          "compile_commands.json",
          "compile_flags.txt",
          "configure.ac",
          ".git",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
        capabilities = {
          offsetEncoding = { "utf-16" },
        },
      }

      -- Bash Language Server
      vim.lsp.config.bashls = {
        cmd = { "bash-language-server", "start" },
        filetypes = { "sh", "bash" },
        root_markers = { ".git", ".bashrc", ".bash_profile" },
        settings = {
          bashIde = {
            globPattern = "*@(.sh|.inc|.bash|.command)",
          },
        },
      }

      -- LaTeX Language Server (texlab)
      vim.lsp.config.texlab = {
        cmd = { "texlab" },
        filetypes = { "tex", "plaintex", "bib" },
        root_markers = {
          ".latexmkrc",
          ".texlabroot",
          "texlabroot",
          "Tectonic.toml",
          ".git",
        },
        settings = {
          texlab = {
            auxDirectory = ".",
            bibtexFormatter = "texlab",
            build = {
              args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
              executable = "latexmk",
              forwardSearchAfter = false,
              onSave = false,
            },
            chktex = {
              onEdit = false,
              onOpenAndSave = false,
            },
            diagnosticsDelay = 300,
            formatterLineLength = 80,
            forwardSearch = {
              args = {},
            },
            latexFormatter = "latexindent",
            latexindent = {
              modifyLineBreaks = false,
            },
          },
        },
      }

      -- Markdown Language Server (marksman)
      vim.lsp.config.marksman = {
        cmd = { "marksman", "server" },
        filetypes = { "markdown", "markdown.mdx" },
        root_markers = { ".marksman.toml", ".git" },
      }

      -- Enable all configured language servers
      vim.lsp.enable({ "lua_ls", "clangd", "bashls", "texlab", "marksman" })
    end,
  },

  -- https://github.com/folke/lazydev.nvim
  -- this is to help the language server be aware of stuff that it should be aware of
  {
    "folke/lazydev.nvim",
    enabled = false,
    ft = "lua",
    opts = {},
  },
}
