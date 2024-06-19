-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
--  TODO: many keymaps still in plugin configs and which-key config

--[[----------------------
------ my keymaps --------
--------------------------
    These are the keymaps I have carried around for a while
    Keymaps for better default experience
    See `:help vim.keymap.set()`
    for modes, see `:help map-modes`
--]]

-- remove search highlight with Esc
vim.keymap.set({ 'n' }, '<esc>', ':noh<cr>', { silent = true })
-- disable actions for Space in normal and visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- jumbo scrolling (stationary cursor)
vim.keymap.set('n', '<c-e>', '5<c-e>', { silent = true })
vim.keymap.set('n', '<c-y>', '5<c-y>', { silent = true })

-- automatically open help in vertical split
vim.keymap.set('c', 'vh', 'vert help ', { noremap = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- or another way
-- vim.keymap.set({ "n", "x" }, "j", "gj", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "x" }, "k", "gk", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>w", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", { noremap = true, silent = true })

-- A function and keymapping to toggle cursor position highlighting
vim.api.nvim_create_user_command('Togglecolorcolumn', function()
  if vim.o.colorcolumn == '' then
    vim.o.colorcolumn = '+1'
  else
    vim.o.colorcolumn = ''
  end
end, { desc = 'toggle the colorcolumn at textwidth', nargs = 0 })

-- buffers - TODO how to ignore while in nvim-tree, telescope, etc.
-- vim.keymap.set('n', '<c-n>', ":bnext<cr>", { silent = true })
-- vim.keymap.set('n', '<c-p>', ":bprevious<cr>", { silent = true })

vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

--------------------------
--- kickstart keymaps ----
--------------------------

vim.keymap.set('n', '<leader>x', '<cmd>.lua<CR>', { desc = 'Execute the current line' })
-- this conflicts with "find existing file" from telescope config,
-- but timing/rhythm of the ,, seems to matter
vim.keymap.set('n', '<leader><leader>x', '<cmd>source %<CR>', { desc = 'Execute the current file' })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

--------------------------
------ my helper fns -----
--------------------------

-- A function and keymapping to toggle 80th column highlighting
vim.api.nvim_create_user_command('Togglecolorcolumn', function()
  if vim.o.colorcolumn == '' then
    vim.o.colorcolumn = '+1'
  else
    vim.o.colorcolumn = ''
  end
end, { desc = 'toggle the colorcolumn at textwidth', nargs = 0 })

-- A function and keymapping to toggle cursor position highlighting
vim.api.nvim_create_user_command('Togglecursorline', function()
  if vim.o.cursorline == false then
    vim.o.cursorline = true
  else
    vim.o.cursorline = false
  end
end, { desc = 'toggle the cursorline', nargs = 0 })

--------------------------
------ some notes --------
--------------------------

-- some ideas from https://www.youtube.com/watch?v=KGJV0n70Mxs

-- set up a function for setting keymaps with default options
-- local kset = vim.keymap.set
-- local kopts = { noremap = true, silent = true }
--
-- -- keep the window centered while navigating searches
-- keymap("n", "n", "nzz", opts)
-- keymap("n", "N", "Nzz", opts)
-- keymap("n", "*", "*zz", opts)
-- keymap("n", "#", "#zz", opts)
-- keymap("n", "g*", "g*zz", opts)
-- keymap("n", "g#", "g#zz", opts)
--
-- -- Stay in indent mode
-- keymap("v", "<", "<gv", opts)
-- keymap("v", ">", ">gv", opts)
--
-- -- keep the yanked register when replacing text
-- keymap("x", "p", [["_dP]])
--
-- -- add some stuff to the mouse menu
-- vim.cmd [[:amenu 10.100 mousemenu.Goto\ Definition <cmd>lua vim.lsp.buf.definition()<CR>]]
-- vim.cmd [[:amenu 10.110 mousemenu.References <cmd>lua vim.lsp.buf.references()<CR>]]
-- -- vim.cmd [[:amenu 10.120 mousemenu.-sep- *]]
-- vim.keymap.set("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>")
-- vim.keymap.set("n", "<Tab>", "<cmd>:popup mousemenu<CR>")
