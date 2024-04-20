--{{{ Preamble

--{{{ Set up leader, folding, and package manager
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- to enable folding for this file
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  pattern = { '/home/*/.config/nvim/init.lua' },
  command = 'setlocal foldmethod=marker',
})

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)
--}}}

--[[ {{{ Todos and notes

Markdown support
  --folding--
  spaces between folding
  distinctive heading font formatting
  linking and references
  auto-formatting (https://github.com/stevearc/conform.nvim)

Margin notes
  choose a syntax to start a short tag in the 84th column
  create an alias to grep them into the quickfix list
  create a conceal rule to minimize them by default

Buffer support

Zen mode aesthetics (with manual switch on/off)
  junegunn/goyo.vim
  junegunn/limelight.vim
    and consider
    autocmd! User GoyoEnter Limelight
    autocmd! User GoyoLeave Limelight!
  folke/zen-mode.nvim

Grammar(ly) linting

Thesaurus-based completion

--}}} --]]

--}}}

--{{{ Plugin install and initial configurations
--
-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({

  { --{{{ Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
  }, --}}}

  { --{{{ Useful plugin to show you pending keybinds.
   'folke/which-key.nvim',
    opts = {}
    -- see below for custom key registrations (search 'which.key.register')
  }, --}}}

  { --{{{ Theme inspired by Atom
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
        require('onedark').setup  {
          -- Main options --
          style = 'darker', -- Default theme style. Choose between 'dark', 'darker', 
                            -- 'cool', 'deep', 'warm', 'warmer' and 'light'
          transparent = true,  -- Show/hide background
          term_colors = true, -- Change terminal color as per the selected theme style
          ending_tildes = false, -- Show the end-of-buffer tildes. By default they are hidden
          cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu
          -- 
          -- toggle theme style ---
          toggle_style_key = "<leader>ts", -- keybind to toggle theme style.
                                           -- Leave it nil to disable it, or set it to a string,
        --                                 -- for example "<leader>ts"
          toggle_style_list = {'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'},
          -- 
          -- Change code style ---
          -- Options are italic, bold, underline, none
          -- You can configure multiple style with comma separated, For e.g., keywords = 'italic,bold'
          code_style = {
              comments = 'italic',
              keywords = 'none',
              functions = 'none',
              strings = 'none',
              variables = 'none'
          },
          -- 
          -- Lualine options --
          lualine = {
              transparent = true, -- lualine center bar transparency
          },
          -- 
          -- Custom Highlights --
          colors = {}, -- Override default colors
          highlights = {}, -- Override highlight groups
          -- 
          -- Plugins Config --
          diagnostics = {
              darker = true, -- darker colors for diagnostic
              undercurl = true,   -- use undercurl instead of underline for diagnostics
              background = true,    -- use background color for virtual text
          },
      }
      vim.cmd.colorscheme 'onedark'
    end,
  }, --}}}

  { --{{{ Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'onedark',
        component_separators = '|',
        section_separators = '',
      },
    },
  }, --}}}

  { --{{{ Highlight, edit, and navigate code (tresitter.nvim)
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  }, --}}}

  { --{{{ Markdown support
    -- FIXME enabling this plugin breaks normal folding commands
    --'ixru/nvim-markdown',
    -- config = function()
    --     vim_markdown_toc_autofit = 1
    -- end,
    --
    -- The original
    'preservim/vim-markdown',
    config = function()
      vim.g.vim_markdown_toc_autofit = 1
      vim.g.vim_markdown_auto_insert_bullets = 0
      vim.g.vim_markdown_new_list_item_indent = 0
    end,
  }, --}}}

}, {}) --}}} plugin install

--{{{ Setting options
--
-- See `:help vim.o`
-- and https://github.com/nanotee/nvim-lua-guide#managing-vim-options
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.go.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- relative numbering
vim.o.number = true
vim.o.relativenumber = false

-- might want to enable this per filetype eventually
-- not sure yet why 'gq' doesn't work well
vim.o.textwidth = 80

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.o.smartindent = true
vim.o.smarttab = true

vim.o.scrolloff = 5

vim.o.wrap = true
vim.o.linebreak = true

vim.o.ruler = true

vim.o.splitright = true

-- Fix markdown indentation settings
-- vim.g.markdown_folding = 1

--}}} setting options

--{{{ Autocmds and filetype settings-- wrap and check for spell in text filetypes

-- vim.api.nvim_create_autocmd("FileType", {
--   group = augroup("wrap_spell"),
--   pattern = { "gitcommit", "markdown" },
--   callback = function()
--     vim.opt_local.wrap = true
--     vim.opt_local.spell = true
--   end,
-- })

-- see https://github.com/preservim/vim-markdown/issues/232
-- and https://github.com/preservim/vim-markdown/issues/390
--
-- au FileType markdown setlocal formatlistpat=^\\s*\\d\\+[.\)]\\s\\+\\\|^\\s*[*+~-]\\s\\+\\\|^\\(\\\|[*#]\\)\\[^[^\\]]\\+\\]:\\s | setlocal comments=n:> | setlocal formatoptions+=cn
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = {"markdown"},
--   callback = function()
--     setlocal formatlistpat=^\\s*\\d\\+[.\)]\\s\\+\\\|^\\s*[*+~-]\\s\\+\\\|^\\(\\\|[*#]\\)\\[^[^\\]]\\+\\]:\\s 
--     setlocal comments=n:> 
--     setlocal formatoptions+=cn
--   end,
-- })

--}}} autocmds and filetypes

--{{{ Basic Keymaps
--
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- jumbo scrolling
vim.keymap.set('n', '<c-e>', '5<c-e>', { silent = true })
vim.keymap.set('n', '<c-y>', '5<c-y>', { silent = true })

-- automatically open help in vertical split
vim.keymap.set('c', 'vh', 'vert help ', { noremap = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- A function and keymapping to toggle cursor position highlighting
vim.api.nvim_create_user_command('Togglecolorcolumn', function()
  if vim.o.colorcolumn == '' then
    vim.o.colorcolumn = '+0'
  else
    vim.o.colorcolumn = ''
  end
end, { desc = 'toggle the colorcolumn at textwidth', nargs = 0 })
require('which-key').register {
  ['<leader>'] = {
    z = {
      name = '+config',
      C = { '<cmd>set cursorcolumn!<cr><cmd>set cursorline!<cr>', '[C]ursor highlight toggle' },
      c = { '<cmd>Togglecolorcolumn<cr>', '[c]olorcolumn toggle at textwidth' },
    },
  },
}

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})
--}}} basic keymaps

--{{{ Configure Treesitter
--
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
--
vim.defer_fn(function()
---@diagnostic disable-next-line: missing-fields
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = {
      'bash',
      'c',
      'cpp',
      'diff',
      'json',
      'lua',
      'markdown',
      'markdown_inline',
      'python',
      'regex',
      'rust',
      'vim',
      'vimdoc',
      'yaml',
    },

    -- Autoinstall languages that are not installed. Defaults to false (but you
    -- can change for yourself!)
    auto_install = false,

    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  }
end, 0) --}}}
