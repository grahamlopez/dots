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

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- execute the current line and current file
vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
vim.keymap.set("v", "<leader>x", "<cmd>'<,'>.lua<CR>", { desc = "Execute the selection" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })

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
