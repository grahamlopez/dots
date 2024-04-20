-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/whichkey.lua
--[[
    to query a current mapping use `:map <leader>h` and its mode variants
    `:map` by itself will show all user-defined mappings
    to ask about a key that starts with control, type `C-v` first, then the key sequence

    see a default mapping, use `:help` followed by the keysequence, or e.g. CTRL-P

    for modes, see `:help map-modes`
--]]
local M = {
  -- https://github.com/folke/which-key.nvim
  "folke/which-key.nvim",
}

function M.config()
  require("which-key").setup({
    key_labels = {
      ["<space>"] = "SPC",
      ["<cr>"] = "RET",
      ["<tab>"] = "TAB",
    },
    window = {
      border = "rounded",
      position = "bottom",
      margin = { 1, 3, 1, 3 },
      padding = { 1, 3, 1, 3 },
      winblend = 10,
    },
  })

  -- a wrapper to have slightly nicer error output via pcall()
  -- and to shorten the keymap defns
  local function run_cmd_winput(command)
    local input = vim.fn.input(":" .. command .. " ")
    local ok, err = pcall(function()
      vim.cmd(command .. " " .. input)
    end)
    if not ok then
      print("Error: " .. err)
    end
  end

  local function find_configs()
    require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
  end

  -- non-leader bindings
  -- 'gd' goto definition (built-in)
  -- <c-g> find word under cursor (telescope grep)
  -- <c-k> vim help for word under cursor (telescope) - should these k/K be combined/adapted based on filetype and/or path?
  -- <c-K> man page for word under cursor (telescope)
  -- <c-h> lsp hover
  -- <c-b> buffer list (telescope) - watch out for collisions with other utilities e.g. telescope or whatever
  -- <c-n/p> forward/back in buffer list (ensure it doesn't conflict with other things e.g. telescope)

  -- all of these start with <leader>
  local nvs_mode_mappings = {
    a = {
      name = " [a]pps",
      a = { "<cmd>AerialToggle!<cr>", "[a]erial toggle" },
    },

    b = {
      name = " [b]uffer",
      -- TODO make <leader><tab> switch buffers?
      b = { "<cmd>edit #<cr>", "[b]uffer switch" }, -- equiv to <c-^>
      d = { "<cmd>bdelete<cr>", "[b]delete" },   -- equiv to <c-^>
      l = { "<cmd>lua require'telescope.builtin'.buffers()<cr>", "[f]ind buffers" },
      n = { "<cmd>bnext<cr>", "b[n]ext" },
      p = { "<cmd>bprevious<cr>", "b[p]revious" },
    },

    h = {
      name = " [h]elp",
      h = {
        function()
          run_cmd_winput("help")
        end,
        "get [h]elp",
      },
      k = { ":help <c-r><c-w><cr>", "help for word under cursor" },
      m = {
        function()
          run_cmd_winput("map")
        end,
        "show key [m]apping",
      },
      v = {
        function()
          run_cmd_winput("vert help")
        end,
        "get [v]ertical help",
      },
    },

    f = {
      name = " [f]ind stuff",
      C = { function() find_configs() end, "neovim [C]onfig", },
      b = { "<cmd>lua require'telescope.builtin'.buffers()<cr>", "find [b]uffers" },
      e = { "<cmd>NvimTreeToggle<cr>", "[e]xplorer" },
      F = { "<cmd>lua require'telescope.builtin'.find_files()<cr>", "find [F]iles" }, -- TODO needs to be DRY'ed with telescope.lua
      f = { "<cmd>lua require'telescope.builtin'.grep_string( { path_display = { 'smart'}, only_sort_text = true, word_match = '-w', search = '' } )<cr>", "[f]uzzy find" },
      g = { "<cmd>lua require'telescope.builtin'.live_grep()<cr>", "[g]rep" },
      h = { "<cmd>lua require'telescope.builtin'.help_tags()<cr>", "[h]elp tags" },
    },

    l = {
      name = " [l]anguage server",
      d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "goto [d]efinition" },
      f = { "<cmd>lua vim.lsp.buf.format({async = true})<cr>", "Format" },
      k = { "<cmd>lua vim.lsp.buf.hover()<CR>", "[h]over" },
    },

    s = {
      name = " [s]elect (TS)", -- optional group name
      s = {
        "<cmd>lua require'nvim-treesitter.incremental_selection'.node_incremental()<CR>",
        "[s]tart selection",
      },
      i = { "<cmd>lua require'nvim-treesitter.incremental_selection'.node_incremental()<CR>", "[i]ncrement" },
      c = {
        "<cmd>lua require'nvim-treesitter.incremental_selection'.scope_incremental()<CR>",
        "s[c]ope incremental",
      },
      d = { "<cmd>lua require'nvim-treesitter.incremental_selection'.node_decremental()<CR>", "[d]ecrement" },
    },

    u = {
      -- wrap, textwidth, conceal, spelling, diagnostics
      name = " [u]i",
      C = { "<cmd>Togglecolorcolumn<cr>", "[c]olorcolumn toggle at textwidth" },
      c = { "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", "[c]olorscheme" },
      t = { "<cmd>TransparentToggle<cr>", "[t]oggle transparent background" },
    },
  }

  local nvs_mode_opts = {
    mode = { "n", "v", "s" },
    prefix = "<leader>",
  }

  require("which-key").register(nvs_mode_mappings, nvs_mode_opts)
end

--[[
    This is the launch way of setting up whichkey
function M.config()
  local mappings = {
    q = { "<cmd>confirm q<CR>", "Quit" },
    h = { "<cmd>nohlsearch<CR>", "NOHL" },
    [";"] = { "<cmd>tabnew | terminal<CR>", "Term" },
    v = { "<cmd>vsplit<CR>", "Split" },
    b = { name = "Buffers" },
    d = { name = "Debug" },
    f = { name = "Find" },
    g = { name = "Git" },
    l = { name = "LSP" },
    p = { name = "Plugins" },
    t = { name = "Test" },
    a = {
      name = "Tab",
      n = { "<cmd>$tabnew<cr>", "New Empty Tab" },
      N = { "<cmd>tabnew %<cr>", "New Tab" },
      o = { "<cmd>tabonly<cr>", "Only" },
      h = { "<cmd>-tabmove<cr>", "Move Left" },
      l = { "<cmd>+tabmove<cr>", "Move Right" },
    },
    T = { name = "Treesitter" },
  }

  local which_key = require "which-key"
  which_key.setup {
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = false,
        nav = false,
        z = false,
        g = false,
      },
    },
    window = {
      border = "rounded",
      position = "bottom",
      padding = { 2, 2, 2, 2 },
    },
    ignore_missing = true,
    show_help = false,
    show_keys = false,
    disable = {
      buftypes = {},
      filetypes = { "TelescopePrompt" },
    },
  }

  local opts = {
    mode = "n", -- NORMAL mode
    prefix = "<leader>",
  }

  which_key.register(mappings, opts)
end
--]]

return M
