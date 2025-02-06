-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/keymaps.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--[[
    These are the keymaps I have carried around for a while
    Keymaps for better default experience
    See `:help vim.keymap.set()`
    for modes, see `:help map-modes`
--]]
vim.keymap.set({ 'n' }, '<esc>', ":noh<cr>", { silent = true })
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- jumbo scrolling
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

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")


------------------------------------------------------------------------
---
-- Set up the majority of command shortcut keybindings
-- prefer to use native vim keymapping facilities instead of which-key
-- to allow for disabling which-key and having mappings still work
--

-- first, some conveniences for use in the following mapping specs
local tb = require('telescope.builtin')

vim.keymap.set('n', '<c-b>', tb.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<c-f>', tb.current_buffer_fuzzy_find, { desc = 'Telescope current buffer search' })
vim.keymap.set('n', '<c-g>', tb.live_grep, { desc = 'Telescope live grep' })

vim.keymap.set('n', '<leader>bb', tb.buffers, { desc = 'Telescope buffers' })

vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', tb.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', tb.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>ta', tb.autocommands, { desc = 'Telescope autocommands' })
vim.keymap.set('n', '<leader>tb', tb.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>tc', tb.commands, { desc = 'Telescope commands' })
vim.keymap.set('n', '<leader>tC', tb.command_history, { desc = 'Telescope command history' })
vim.keymap.set('n', '<leader>tf', tb.filetypes, { desc = 'Telescope file types' })
vim.keymap.set('n', '<leader>th', tb.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>tH', tb.highlights, { desc = 'Telescope highlights' })
vim.keymap.set('n', '<leader>tj', tb.jumplist, { desc = 'Telescope jump list' })
vim.keymap.set('n', '<leader>tk', tb.keymaps, { desc = 'Telescope normal mode keymaps' })
vim.keymap.set('n', '<leader>tl', tb.loclist, { desc = 'Telescope location list' })
vim.keymap.set('n', '<leader>tm', tb.marks, { desc = 'Telescope marks' })
vim.keymap.set('n', '<leader>tM', tb.man_pages, { desc = 'Telescope man pages' })
vim.keymap.set('n', '<leader>to', tb.oldfiles, { desc = 'Telescope oldfiles' })
vim.keymap.set('n', '<leader>tq', tb.quickfix, { desc = 'Telescope quickfix' })
vim.keymap.set('n', '<leader>tQ', tb.quickfixhistory, { desc = 'Telescope quickfix history' })
vim.keymap.set('n', '<leader>tr', tb.registers, { desc = 'Telescope registers' })
vim.keymap.set('n', '<leader>ts', tb.spell_suggest, { desc = 'Telescope spell suggest' })
vim.keymap.set('n', '<leader>tS', tb.search_history, { desc = 'Telescope search history' })
vim.keymap.set('n', '<leader>tt', tb.tags, { desc = 'Telescope tags' })
vim.keymap.set('n', '<leader>tv', tb.vim_options, { desc = 'Telescope vim options' })

vim.keymap.set('n', '<leader>uc', "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", { desc = 'Telescope colorscheme' })
vim.keymap.set('n', '<leader>ut', "<cmd>TransparentToggle<cr>", { desc = 'Telescope help tags' })

vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
vim.keymap.set("v", "<leader>x", "<cmd>'<,'>.lua<CR>", { desc = "Execute the selection" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })

local wk = require("which-key")
wk.add({
  { "<leader>b", group = "Buffer" },
  { "<leader>f", group = "File" },
  { "<leader>t", group = "Telescope" },
  { "<leader>u", group = "UI" },
})

-- some ideas from https://www.youtube.com/watch?v=KGJV0n70Mxs

-- set up a function for setting keymaps with default options
-- local keymap = vim.keymap.set
-- local opts = { noremap = true, silent = true }
-- 
-- -- keep the window centered while navigating searches
-- keymap("n", "n", "nzz", opts)
-- keymap("n", "N", "Nzz", opts)
-- keymap("n", "*", "*zz", opts)
-- keymap("n", "#", "#zz", opts)
-- keymap("n", "g*", "g*zz", opts)
-- keymap("n", "g#", "g#zz", opts)
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
