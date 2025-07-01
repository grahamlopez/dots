-- helper function for blink.cmp emacs style completion
local has_words_before = function()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return false
  end
  local line = vim.api.nvim_get_current_line()
  return line:sub(col, col):match("%s") == nil
end

return {

  --
  --      Pickers
  --

  -- https://github.com/folke/snacks.nvim
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      picker = {
        enabled = true,
        layout = {
          cycle = true,
          --- Use the default layout or vertical if the window is too narrow
          preset = function()
            return vim.o.columns >= 160 and "default" or "vertical"
          end,
        },
        win = {
          -- input window
          input = {
            keys = {
              ["<a-s>"] = { "flash", mode = { "n", "i" } },
              ["<c-y>"] = { "preview_scroll_up", mode = { "n", "i" } },
              ["<c-e>"] = { "preview_scroll_down", mode = { "i", "n" } },
            },
            b = {
              minipairs_disable = true,
            },
          },
          -- result list window
          list = {
            keys = {
              ["<c-y>"] = "preview_scroll_up",
              ["<c-e>"] = "preview_scroll_down",
            },
            wo = {
              conceallevel = 2,
              concealcursor = "nvc",
            },
          },
          -- preview window
          preview = {
            keys = {
              ["<Esc>"] = "cancel",
              ["q"] = "close",
              ["i"] = "focus_input",
              ["<a-w>"] = "cycle_win",
            },
          },
        },
      },
    },
  },

  -- https://github.com/nvim-telescope/telescope.nvim
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      -- useful site for unicode: https://symbl.cc/en/unicode/blocks/box-drawing/
      "nvim-telescope/telescope-symbols.nvim",
    },

    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          layout_strategy = "flex",
          layout_config = {
            flip_columns = 160, -- Use horizontal layout if columns >= 160
            horizontal = { preview_cutoff = 120 },
            vertical = { preview_cutoff = 40 },
            prompt_position = "top", -- Places prompt above the results
          },
          sorting_strategy = "ascending", -- This makes results list top-down when prompt is on top
          mappings = { -- https://github.com/nvim-telescope/telescope.nvim#default-mappings

            -- use '<C-/>' and '?' in insert and normal mode, respectively, to
            -- show the actions mapped to your picker
            i = {
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,
              ["<C-e>"] = actions.preview_scrolling_down,
              ["<C-y>"] = actions.preview_scrolling_up,
            },
            n = {
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,
              ["<C-e>"] = actions.preview_scrolling_down,
              ["<C-y>"] = actions.preview_scrolling_up,
            },
          },
          pickers = { -- https://github.com/nvim-telescope/telescope.nvim#pickers
          },
        },
      })
    end,
  },

  --
  --      Keybindings
  --

  --[[
        to query a current mapping use `:map <leader>h` and its mode variants
        `:map` by itself will show all user-defined mappings
        to ask about a key that starts with control, type `C-v` first, then the key sequence

        see a default mapping, use `:help` followed by the keysequence, or e.g. CTRL-P

        for modes, see `:help map-modes`
    --]]
  {
    "folke/which-key.nvim", -- https://github.com/folke/which-key.nvim
    config = function()
      require("which-key").setup({
        win = {
          width = 0.9,
          height = { min = 4, max = 25 },
          col = 0.5,
          row = -5,
          border = "rounded",
          padding = { 1, 3 },
          title = true,
          title_pos = "center",
          -- wo = { winblend = 15 }, -- BUG: this is fully transparent on WSL
        },
        icons = {
          mappings = false,
        },
      })
    end,
  },

  --
  --      Completion
  --

  -- https://github.com/Saghen/blink.cmp
  -- TODO: I would like to have signature insertion with placeholders
  {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    dependencies = { "rafamadriz/friendly-snippets" },

    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      --[[ emacs style:
      keymap = {
        preset = "none",

        -- If completion hasn't been triggered yet, insert the first suggestion; if it has, cycle to the next suggestion.
        ["<Tab>"] = {
          function(cmp)
            if has_words_before() then
              return cmp.insert_next()
            end
          end,
          "fallback",
        },
        -- Navigate to the previous suggestion or cancel completion if currently on the first one.
        ["<S-Tab>"] = { "insert_prev" },

        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },

        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },
      completion = {
        menu = { auto_show = false, enabled = true },
        list = {
          selection = { preselect = false },
          cycle = { from_top = false },
        },
      },

      --]]

      -- default configuration
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = { preset = "super-tab" },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = {
        menu = {
          auto_show = false,
          enabled = true,
        },
        documentation = { auto_show = false },
      },

      signature = {
        -- enabled = true,
        -- window = { border = "single" },
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
      --]]
    },
    opts_extend = { "sources.default" },
  },

  -- Auto-completion for various sources (beyond LSP)
  -- https://github.com/hrsh7th/nvim-cmp
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
      },
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = function(entry, vim_item)
            -- Kind icons
            local icons = {
              Text = "",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰇽",
              Variable = "󰂡",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "󰅲",
            }
            vim_item.kind =
              string.format("%s %s", icons[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
      })

      -- Command line completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      -- Search completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },

  --
  --      Syntax
  --

  -- https://github.com/nvim-treesitter/nvim-treesitter
  {
    --[[
    Without treesitter, using regex highlighting by default e.g. use :Inspect to
    see what is being used.

    The textobjects and refactor modules seem kinda cool, but have been really
    buggy for me, so they are disabled for now
    --]]
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      {
        -- https://github.com/nvim-treesitter/nvim-treesitter-context
        "nvim-treesitter/nvim-treesitter-context", -- FIXME: not working

        -- RFE: lazyvim's context is way better than mine
        -- and also consider https://github.com/SmiteshP/nvim-navic
      },
    },
    --  {
    --    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    --    "nvim-treesitter/nvim-treesitter-textobjects",
    --  },
    --  {
    --    -- https://github.com/nvim-treesitter/nvim-treesitter-refactor
    --    "nvim-treesitter/nvim-treesitter-refactor"
    --  },

    -- recommended YT vid for understanding treesitter
    -- https://www.youtube.com/watch?v=kYXcxJxJVxQ
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup({
        -- https://github.com/nvim-treesitter/nvim-treesitter/wiki/List-of-parsers
        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "fortran",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "rust",
          "vim",
          "vimdoc",
        },
        auto_install = true, -- for new filetypes not listed above
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          -- keymaps = { -- move these to be with the other keybindings (and improve them)
          --   init_selection = "<leader>ss",
          --   node_incremental = "<leader>si",
          --   scope_incremental = "<leader>sc",
          --   node_decremental = "<leader>sd",
          -- },
        },
      })
    end,
  },

  --
  --      Session Management
  --

  -- https://github.com/folke/persistence.nvim
  {
    -- Session management. This saves your session in the background,
    -- keeping track of open buffers, window arrangement, and more.
    -- You can restore sessions when returning through the dashboard.
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      branch = false,
      need = 2,
    },
    config = function() -- part of what's needed to preserve bufferline ordering
      require("persistence").setup({
        options = { "globals" }, -- include other options as needed
        pre_save = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
        end,
      })
    end,
  },

  --
  --      File explorer
  --

  --
  --      Tab pages, zoom window
  --      - for "zooming" windows (:tab split)
  --      - for isolating cwd
  --      - how to minimize cognitive load
  --        - visual cues (lualine config)
  --        - keybindings

  --
  --      Clipboards and Registers
  --

  --
  --      Spelling
  --      - read through and understand spell checking settings, files, workflows
  --

  --
  --      Movement
  --

  -- https://github.com/folke/flash.nvim
  {
    "folke/flash.nvim",
    enabled = false,
    event = "VeryLazy",
    specs = { -- not sure if this part should go in the snacks picker config
      {
        "folke/snacks.nvim",
        opts = {
          picker = {
            win = {
              input = {
                keys = {
                  ["<a-s>"] = { "flash", mode = { "n", "i" } },
                  ["s"] = { "flash" },
                },
              },
            },
            actions = {
              flash = function(picker)
                require("flash").jump({
                  pattern = "^",
                  label = { after = { 0, 0 } },
                  search = {
                    mode = "search",
                    exclude = {
                      function(win)
                        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                          ~= "snacks_picker_list"
                      end,
                    },
                  },
                  action = function(match)
                    local idx = picker.list:row2idx(match.pos[1])
                    picker.list:_move(idx, true, true)
                  end,
                })
              end,
            },
          },
        },
      },
    },
  },
}
