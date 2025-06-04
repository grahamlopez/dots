return {

  --
  --      Movement
  --

  -- https://github.com/folke/flash.nvim
  {
    "folke/flash.nvim",
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
                        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
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
    tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      -- useful site for unicode: https://symbl.cc/en/unicode/blocks/box-drawing/
      "nvim-telescope/telescope-symbols.nvim",
    },

    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          -- TODO unify with snacks: vertical if >160 columnss available
          layout_strategy = "vertical",
          mappings = { -- https://github.com/nvim-telescope/telescope.nvim#default-mappings

            -- use '<C-/>' and '?' in insert and normal mode, respectively, to
            -- show the actions mapped to your picker

            i = {
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
            },
            n = {
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
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
          wo = { winblend = 15 },
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

  -- Auto-completion for various sources (beyond LSP)
  -- https://github.com/hrsh7th/nvim-cmp
  {
    "hrsh7th/nvim-cmp",
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
            vim_item.kind = string.format("%s %s", icons[vim_item.kind], vim_item.kind)
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
  --      File explorer
  --

  --
  --      Tab pages, zoom window
  --
}
