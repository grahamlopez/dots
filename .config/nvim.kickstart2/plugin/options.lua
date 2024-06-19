-- [[ Setting options ]]
-- See `:help vim.opt`
-- For more options, you can see `:help option-list`
-- to test the value of an option
--  :lua vim.print(vim.g.variable_name)
--  :lua =vim.g.variable_name
--  :echo vim.g.variable_name

--------------------
-- Tab / indentation
--------------------

-- NOTE: leaving these out for now as we're trying out tpope/vim-sleuth
-- vim.opt.tabstop = 2      -- insert 2 spaces for a tab
-- vim.opt.shiftwidth = 2   -- the number of spaces inserted for each indentation
-- vim.opt.softtabstop = 2
-- vim.opt.expandtab = true -- convert tabs to spaces
-- vim.opt.smartindent = true

----------------
--- Behavior ---
----------------

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

vim.opt.completeopt = { 'menuone', 'noselect', 'noinsert' } -- For a better completion experience (mostly just for cmp)
vim.opt.foldmethod = 'expr' -- enable treesitter-based folding
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldenable = true
vim.opt.foldlevel = 9

vim.opt.hidden = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Enable mouse mode with 'a', can be useful for resizing splits for example!
-- But I have also had troublesome interactions with clipboards, etc.
vim.opt.mouse = ''

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- TODO: might want to enable this per filetype eventually
-- not sure yet why 'gq' doesn't work well
vim.opt.textwidth = 80

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Save undo history
vim.opt.undofile = true

-- Decrease update time
vim.opt.updatetime = 250

vim.opt.virtualedit = 'block'

vim.opt.winheight = 5
vim.opt.winminheight = 5
vim.opt.winwidth = 5
vim.opt.winminwidth = 5

----------------
-- Appearance --
----------------

-- Enable break indent
vim.opt.breakindent = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.opt.relativenumber = true

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

vim.opt.termguicolors = true -- NOTE: You should make sure your terminal supports this (most do)

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 5

----------------
---- Search ----
----------------

-- Set highlight on search
vim.opt.hlsearch = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
