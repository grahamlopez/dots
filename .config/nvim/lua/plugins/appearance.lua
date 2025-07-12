return {

  --
  --      Theming
  --
  --      https://vimcolorschemes.com/i/top

  -- https://github.com/xiyaowong/transparent.nvim
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 900,
    config = function()
      -- vim.cmd.colorscheme("nightfox")
    end,
  },

  -- https://github.com/f-person/auto-dark-mode.nvim
  {
    -- neovim detects terminal background at startup, BUT
    -- doesn't work inside tmux
    -- doesn't affect already-running instances
    -- not needed anymore? https://github.com/vimpostor/vim-lumen?tab=readme-ov-file#is-this-plugin-still-needed-with-latest-vim
    -- this works, but TMUX doesn't propogate the DEC 2031 escape sequence to
    -- applications running inside of it
    -- but looks like there is a merged PR: https://github.com/tmux/tmux/pull/4353
    --
    -- FIXME: this doesn't work inside of tmux anymore. Consider moving to
    -- something built-in like an autocommand that reads the theme setting from a file, or
    -- something similar
    {
      "f-person/auto-dark-mode.nvim",
      opts = {
        set_dark_mode = function()
          vim.api.nvim_set_option_value("background", "dark", {})
          vim.cmd.colorscheme("tokyonight-moon")
        end,
        set_light_mode = function()
          vim.api.nvim_set_option_value("background", "light", {})
          vim.cmd.colorscheme("default")
        end,
        update_interval = 3000,
        fallback = "dark",
      },
    },
  },

  -- https://github.com/catppuccin/nvim
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    transparent = false,
    background = { -- :h background
      light = "latte",
      dark = "mocha",
    },
  },

  -- https://github.com/EdenEast/nightfox.nvim
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/nordtheme/vim
  -- TODO: maybe find a better nord theme implementation
  {
    "nordtheme/vim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/folke/tokyonight.nvim
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      light_style = "day",
      day_brightness = 0.3, -- 0 (dull) to 1 (virbrant)
      transparent = false,
    },
  },

  -- https://github.com/Mofiqul/dracula.nvim
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/shaunsingh/solarized.nvim
  -- FIXME: something might be wrong with this solarized theme
  {
    "shaunsingh/solarized.nvim",
    lazy = false,
    priority = 1000,
  },

  -- https://github.com/rebelot/kanagawa.nvim
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = false,
      background = { -- map the value of 'background' option to a theme
        dark = "wave", -- try "dragon" !
        light = "lotus",
      },
      -- remove the background of LineNr, {Sign,Fold}Column and friends
      colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
    },
  },

  --
  --      Statusline and bufferline appearance
  --

  -- https://github.com/nvim-lualine/lualine.nvim
  {
    "nvim-lualine/lualine.nvim", -- https://github.com/nvim-lualine/lualine.nvim
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- https://github.com/nvim-tree/nvim-web-devicons
      lazy = true,
      event = "VeryLazy",
    },

    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require("lualine").setup({
        options = {
          theme = "auto",
          globalstatus = true,
        },
        sections = {
          lualine_c = {
            "tabs",
            { "filename", path = 2 },
          },
        },
      })

      require("nvim-web-devicons").setup({ opts = {} })
    end,
  },

  -- https://github.com/akinsho/bufferline.nvim
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        numbers = "ordinal",
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(require("bufferline").nvim_bufferline)
          end)
        end,
      })
    end,
  },

  --
  --      Folding
  --
  --      ufo vs. origami
  --      + ufo     robust against editing/adding markdown sections
  --      + ufo     fold peeking
  --      + origami 'zm/zr' work easily
  --      + origami folded text displays warnings and gitsigns
  --      + origami 'h/l' open/close folds (re-implemented this myself)
  --
  --      picking ufo for now because the folds get messed up when editing
  --      markdown files when using nvim-origami or anything that uses
  --      treesitter foldexpr() for markdown.
  --      Check with `:set foldmethod? foldexpr?`
  --
  --      Even UFO eventually gets confused; the symptom is that folds will be
  --      automatically closed without requesting it, albeit they are in the
  --      right places
  --
  --      This is improved by only having a single H1 per document as per
  --      https://google.github.io/styleguide/docguide/style.html#document-layout
  --
  --      I haven't been able to find a markdown lsp with fold information,
  --      which would be used by nvim-origami if available (treesitter is
  --      fallback)
  --
  --      NOTE: linkarzu does a lot of manual work to make folding work for him
  --      https://github.com/linkarzu/dotfiles-latest/blob/9932144dcf0674cbe41c764bfac8eb69ebe9127b/neovim/neobean/lua/config/keymaps.lua#L2970
  --

  -- https://github.com/kevinhwang91/nvim-ufo
  {
    "kevinhwang91/nvim-ufo",
    enabled = false, -- FIXME: now I'm having problems with all folds being
    -- closed when returning to normal mode after an edit
    dependencies = {
      "kevinhwang91/promise-async",
    },
    config = function()
      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = ("  ____  󰁂 %d  ____"):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end
      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
        close_fold_kinds = { "comment" }, -- FIXME: doesn't work in lua, maybe due to treesitter
        fold_virt_text_handler = handler,
        preview = {
          mappings = {
            scrollU = "<C-u>",
            scrollD = "<C-d>",
            jumpTop = "gg",
            jumpBot = "G",
            close = "<esc>",
          },
        },
        -- stylua: ignore start
        vim.keymap.set( "n", "zR", require("ufo").openAllFolds, { desc = "Open all folds (UFO)" }),
        vim.keymap.set( "n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds (UFO)" }),
        vim.keymap.set("n", "K", function()
          local winid = require("ufo").peekFoldedLinesUnderCursor()
          if not winid then
            -- RFE: would be cool to add popup git hunk diffs to 'K' as well
            vim.lsp.buf.hover()
          end
        end, { desc = "Peek (UFO Fold, lsp.buf.hover(), etc.)" }),
        --vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds),
        --vim.keymap.set("n", "zm", require("ufo").closeFoldsWith), -- closeAllFolds == closeFoldsWith(0)
        -- stylua: ignore end
      })
    end,
  },

  -- https://github.com/chrisgrieser/nvim-origami
  {
    "chrisgrieser/nvim-origami",
    enabled = false,
    event = "VeryLazy",
    opts = {},
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
    config = function()
      require("origami").setup({
        useLspFoldsWithTreesitterFallback = true, -- required for `autoFold`
        pauseFoldsOnSearch = true,
        foldtext = {
          enabled = true,
          padding = 3,
          lineCount = {
            template = "____  󰁂 %d  ____", -- `%d` is the number of folded lines
            hlgroup = "Comment",
          },
          diagnosticsCount = true, -- uses hlgroups and icons from `vim.diagnostic.config().signs`
          gitsignsCount = true, -- requires `gitsigns.nvim`
        },
        autoFold = {
          enabled = true,
          kinds = { "comment", "imports" }, ---@type lsp.FoldingRangeKind[]
        },
        foldKeymaps = {
          setup = true, -- modifies `h` and `l`
          hOnlyOpensOnFirstColumn = false,
        },
      })
      -- this still has the problem of folds being messed up when e.g. adding a
      -- new markdown sub heading with content. Trying to fix it
      -- vim.api.nvim_create_autocmd("FileType", {
      --   pattern = "markdown",
      --   callback = function()
      --     vim.opt_local.foldmethod = "syntax"
      --   end,
      -- })
    end,
  },

  --
  --      Markdown
  --
  --  IDEA: wishlish
  --  - folded ``` code blocks should not disappear still show the foldtext
  --    Workarounds:
  --    - always use ```label with code = { style = "language" } setting
  --      - partial WAR: shows the language label, but not the foldtext
  --    - disable for codeblocks with code = { style = "none" }
  --    - can we use "patterns" from the plugin config?
  --  - closed folds (i.e. headings) with conceal still show my foldtext UPSTREAM: request

  -- https://github.com/MeanderingProgrammer/render-markdown.nvim
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = true,
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- RFE: would like finer-grained toggles e.g. render_modes, anti_conceal
      render_modes = true,
      anti_conceal = {
        enabled = true,
      },
      code = {
        style = "none", -- or "language", "normal", "full"
        sign = false,
        width = "block",
      },
      heading = {
        width = "full",
        sign = false,
      },
      completions = { blink = { enabled = true } }, -- for callouts completions
    },
  },

  --
  --      Outline
  --

  -- https://github.com/hedyhli/outline.nvim
  -- see linkarzu's vid: https://youtu.be/UqLEKe7o2zg
  {
    "hedyhli/outline.nvim",
    enabled = false,
    cmd = { "Outline", "OutlineOpen" },
    opts = {
      outline_window = {
        position = "right",
        width = 25,
        wrap = false,
        auto_close = false,
        auto_jump = false,
        jump_highlight_duration = 300,
      },
      outline_items = {
        show_symbol_details = true,
        show_symbol_lineno = false,
        highlight_hovered_item = true,
        auto_set_cursor = true,
      },
      symbols = {
        filter = {
          -- Remove some symbols for cleaner view
          "String",
          "Number",
          "Boolean",
          "Array",
          "Object",
          "Key",
          "Null",
        },
      },
      preview_window = {
        auto_preview = false,
        open_hover_on_preview = false,
        width = 50,
        min_width = 50,
        relative = "editor",
        border = "rounded",
      },
      guides = {
        enabled = true,
        markers = {
          bottom = "└",
          middle = "├",
          vertical = "│",
        },
      },
      keymaps = {
        close = { "<Esc>", "q" },
        goto_location = "<Cr>",
        peek_location = "o",
        goto_and_close = "<S-Cr>",
        restore_location = "<C-g>",
        hover_symbol = "<C-space>",
        toggle_preview = "K",
        rename_symbol = "r",
        code_actions = "a",
        fold = "h",
        unfold = "l",
        fold_all = "W",
        unfold_all = "E",
        fold_reset = "R",
      },
    },
  },

  -- https://github.com/stevearc/aerial.nvim
  {
    "stevearc/aerial.nvim",
    enabled = false,
    opts = {
      manage_folds = true,
      link_folds_to_tree = true,
      link_tree_to_folds = true,
    },
    -- Optional dependencies
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },

  --
  --      Zen/focus
  --
  --      using snacks.zen() for now until I have more experience and an
  --      identified need for anything different
  --

  -- https://github.com/folke/zen-mode.nvim
  {
    "folke/zen-mode.nvim",
    enabled = false,
    cmd = "ZenMode",
    opts = {
      window = {
        backdrop = 0.95,
        width = 120,
        height = 1,
        options = {
          signcolumn = "no",
          number = false,
          relativenumber = false,
          cursorline = false,
          cursorcolumn = false,
          foldcolumn = "0",
          list = false,
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        twilight = { enabled = true },
        gitsigns = { enabled = false },
        tmux = { enabled = false },
        kitty = {
          enabled = false,
          font = "+4",
        },
      },
    },
  },

  -- https://github.com/folke/twilight.nvim -- for dimming inactive code
  {
    "folke/twilight.nvim",
    enabled = false,
    opts = {
      dimming = {
        alpha = 0.25,
        color = { "Normal", "#ffffff" },
        term_bg = "#000000",
        inactive = false,
      },
      context = 10,
      treesitter = true,
      expand = {
        "function",
        "method",
        "table",
        "if_statement",
      },
      exclude = {},
    },
  },
}
