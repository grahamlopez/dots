-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/keymaps.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--[[
    These are the keymaps I have carried around for a while
    Keymaps for better default experience
    See `:help vim.keymap.set()`
    for modes, see `:help map-modes`

    To see mappings:
    - :help [keys] for built-in keymappings
    - :map [keys] for user-defined keymappings
    use 'c-v [key sequence]' to input a literal keypress involving 
    the control key
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

-- A function and keymapping to toggle colorcolum
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

-- NON-LEADER
vim.keymap.set('n', '<c-b>', tb.buffers, { desc = 'buffer list' })
vim.keymap.set('n', '<c-f>', tb.current_buffer_fuzzy_find, { desc = 'find in current buffer' })
vim.keymap.set('n', '<c-g>', tb.live_grep, { desc = 'live grep' })
vim.keymap.set('n', '<leader>*', tb.grep_string, { desc = 'grep cwd for word under cursor' })

-- TOP LEVEL
vim.keymap.set('n', '<leader>/', tb.live_grep, { desc = 'grep cwd for word under cursor' })

-- BUFFERS
vim.keymap.set('n', '<leader>bb', tb.buffers, { desc = 'buffer list' })

-- FILES
vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = 'find files' })
vim.keymap.set('n', '<leader>fg', tb.live_grep, { desc = 'live grep' })
vim.keymap.set('n', '<leader>fb', tb.buffers, { desc = 'buffers' })
vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = 'help tags' })

-- GIT
vim.keymap.set('n', '<leader>gb', tb.git_branches, { desc = 'git branches' })
vim.keymap.set('v', '<leader>gc', tb.git_bcommits, { desc = 'git commits (range)' })
vim.keymap.set('n', '<leader>gc', tb.git_bcommits, { desc = 'git commits (buffer)' })
vim.keymap.set('n', '<leader>gC', tb.git_commits, { desc = 'git commits (all)' })
vim.keymap.set('n', '<leader>gs', tb.git_status, { desc = 'git status' })
vim.keymap.set('n', '<leader>gS', tb.git_stash, { desc = 'git stash' })

-- HELP
vim.keymap.set('n', '<leader>hh', tb.help_tags, { desc = 'help tags' })
vim.keymap.set('n', '<leader>hm', tb.man_pages, { desc = 'man pages' })
vim.keymap.set('n', '<leader>hw', "<cmd>WhichKey<cr>", { desc = 'which-key' })

-- LSP
vim.keymap.set('n', '<leader>la', "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = 'LSP code actions' })
vim.keymap.set('n', '<leader>lc', tb.lsp_incoming_calls, { desc = 'LSP incoming calls' })
vim.keymap.set('n', '<leader>lC', tb.lsp_outgoing_calls, { desc = 'LSP outgoing calls' })
vim.keymap.set('n', '<leader>ld', tb.lsp_definitions, { desc = 'LSP definitions' })
vim.keymap.set('n', '<leader>lD', tb.diagnostics, { desc = 'LSP diagnostics' })
vim.keymap.set('n', '<leader>li', tb.lsp_implementations, { desc = 'LSP implementations' })
vim.keymap.set('n', '<leader>lr', tb.lsp_references, { desc = 'LSP references' })
vim.keymap.set('n', '<leader>ls', tb.lsp_document_symbols, { desc = 'LSP document symbols' })
vim.keymap.set('n', '<leader>lS', tb.lsp_workspace_symbols, { desc = 'LSP workspace symbols' })
vim.keymap.set('n', '<leader>lt', tb.lsp_type_definitions, { desc = 'LSP type definitions' })

-- TELESCOPE
vim.keymap.set('n', '<leader>ta', tb.autocommands, { desc = 'autocommands' })
vim.keymap.set('n', '<leader>tb', tb.buffers, { desc = 'buffers' })
vim.keymap.set('n', '<leader>tc', tb.commands, { desc = 'commands' })
vim.keymap.set('n', '<leader>tC', tb.command_history, { desc = 'command history' })
vim.keymap.set('n', '<leader>tf', tb.filetypes, { desc = 'file types' })
vim.keymap.set('n', '<leader>th', tb.help_tags, { desc = 'help tags' })
vim.keymap.set('n', '<leader>tH', tb.highlights, { desc = 'highlights' })
vim.keymap.set('n', '<leader>tj', tb.jumplist, { desc = 'jump list' })
vim.keymap.set('n', '<leader>tk', tb.keymaps, { desc = 'normal mode keymaps' })
vim.keymap.set('n', '<leader>tl', tb.loclist, { desc = 'location list' })
vim.keymap.set('n', '<leader>tm', tb.marks, { desc = 'marks' })
vim.keymap.set('n', '<leader>tM', tb.man_pages, { desc = 'man pages' })
vim.keymap.set('n', '<leader>ti', tb.symbols, { desc = 'unicode icons' })
vim.keymap.set('n', '<leader>to', tb.oldfiles, { desc = 'oldfiles' })
vim.keymap.set('n', '<leader>tq', tb.quickfix, { desc = 'quickfix' })
vim.keymap.set('n', '<leader>tQ', tb.quickfixhistory, { desc = 'quickfix history' })
vim.keymap.set('n', '<leader>tr', tb.registers, { desc = 'registers' })
vim.keymap.set('n', '<leader>ts', tb.spell_suggest, { desc = 'spell suggest' })
vim.keymap.set('n', '<leader>tS', tb.search_history, { desc = 'search history' })
vim.keymap.set('n', '<leader>tt', tb.treesitter, { desc = 'treesitter' })
vim.keymap.set('n', '<leader>tT', tb.tags, { desc = 'tags' })
vim.keymap.set('n', '<leader>tv', tb.vim_options, { desc = 'vim options' })

-- UI
vim.keymap.set('n', '<leader>uc', "<cmd>Togglecolorcolumn<cr>", { desc = 'ColorColumn Toggle' })
vim.keymap.set('n', '<leader>uC', "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", { desc = 'colorscheme' })
vim.keymap.set('n', '<leader>ut', "<cmd>TransparentToggle<cr>", { desc = 'Transparent Toggle' })

-- EXECUTE
vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
vim.keymap.set("v", "<leader>x", "<cmd>'<,'>.lua<CR>", { desc = "Execute the selection" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })



local wk = require("which-key")
wk.add({
  mode = { "n", "v", },
  { "<leader>b", group = "Buffer" },
  { "<leader>f", group = "Find" },
  { "<leader>g", group = "Git" },
  { "<leader>h", group = "Help" },
  { "<leader>l", group = "LSP" },
  { "<leader>t", group = "Telescope" },
  { "<leader>u", group = "UI" },
})
------------------------------------------------------------------------
---
--- Iconirific version (not synced / up-to-date)
--[[
vim.keymap.set('n', '<c-b>', tb.buffers, { desc = '󰪸  buffers ' })
vim.keymap.set('n', '<c-f>', tb.current_buffer_fuzzy_find, { desc = '󰺯  find in current buffer ' })
vim.keymap.set('n', '<c-g>', tb.live_grep, { desc = '󰥩  live grep ' })
vim.keymap.set('n', '<leader>*', tb.grep_string, { desc = '󰥩  * for cwd ' })

vim.keymap.set('n', '<leader>bb', tb.buffers, { desc = 'buffers ' })

vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = '󰙅  find files ' })
vim.keymap.set('n', '<leader>fg', tb.live_grep, { desc = '󰥩  live grep ' })
vim.keymap.set('n', '<leader>fb', tb.buffers, { desc = '󰪸  buffers ' })
vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = ' help tags ' })

vim.keymap.set('n', '<leader>gb', tb.git_branches, { desc = ' git branches ' })
vim.keymap.set('v', '<leader>gc', tb.git_bcommits, { desc = 'git commits (range) ' })
vim.keymap.set('n', '<leader>gc', tb.git_bcommits, { desc = 'git commits (buffer) ' })
vim.keymap.set('n', '<leader>gC', tb.git_commits, { desc = 'git commits (all) ' })
vim.keymap.set('n', '<leader>gs', tb.git_status, { desc = 'git status ' })
vim.keymap.set('n', '<leader>gS', tb.git_stash, { desc = 'git stash ' })

vim.keymap.set('n', '<leader>hh', tb.help_tags, { desc = ' help tags ' })
vim.keymap.set('n', '<leader>hm', tb.man_pages, { desc = '  man pages ' })
vim.keymap.set('n', '<leader>hw', "<cmd>WhichKey<cr>", { desc = '  which-key' })

vim.keymap.set('n', '<leader>lc', tb.lsp_incoming_calls, { desc = 'LSP incoming calls ' })
vim.keymap.set('n', '<leader>lC', tb.lsp_outgoing_calls, { desc = 'LSP outgoing calls ' })
vim.keymap.set('n', '<leader>ld', tb.lsp_definitions, { desc = 'LSP definitions ' })
vim.keymap.set('n', '<leader>lD', tb.diagnostics, { desc = 'LSP diagnostics ' })
vim.keymap.set('n', '<leader>li', tb.lsp_implementations, { desc = 'LSP implementations ' })
vim.keymap.set('n', '<leader>lr', tb.lsp_references, { desc = 'LSP references ' })
vim.keymap.set('n', '<leader>ls', tb.lsp_document_symbols, { desc = 'LSP document symbols ' })
vim.keymap.set('n', '<leader>lS', tb.lsp_workspace_symbols, { desc = 'LSP workspace symbols ' })
vim.keymap.set('n', '<leader>lt', tb.lsp_type_definitions, { desc = 'LSP type definitions ' })

vim.keymap.set('n', '<leader>ta', tb.autocommands, { desc = 'autocommands ' })
vim.keymap.set('n', '<leader>tb', tb.buffers, { desc = 'buffers ' })
vim.keymap.set('n', '<leader>tc', tb.commands, { desc = 'commands ' })
vim.keymap.set('n', '<leader>tC', tb.command_history, { desc = 'command history ' })
vim.keymap.set('n', '<leader>tf', tb.filetypes, { desc = 'file types ' })
vim.keymap.set('n', '<leader>th', tb.help_tags, { desc = 'help tags ' })
vim.keymap.set('n', '<leader>tH', tb.highlights, { desc = 'highlights ' })
vim.keymap.set('n', '<leader>tj', tb.jumplist, { desc = 'jump list ' })
vim.keymap.set('n', '<leader>tk', tb.keymaps, { desc = 'normal mode keymaps ' })
vim.keymap.set('n', '<leader>tl', tb.loclist, { desc = 'location list ' })
vim.keymap.set('n', '<leader>tm', tb.marks, { desc = 'marks ' })
vim.keymap.set('n', '<leader>tM', tb.man_pages, { desc = 'man pages ' })
vim.keymap.set('n', '<leader>ti', tb.symbols, { desc = 'unicode icons ' })
vim.keymap.set('n', '<leader>to', tb.oldfiles, { desc = 'oldfiles ' })
vim.keymap.set('n', '<leader>tq', tb.quickfix, { desc = 'quickfix ' })
vim.keymap.set('n', '<leader>tQ', tb.quickfixhistory, { desc = 'quickfix history ' })
vim.keymap.set('n', '<leader>tr', tb.registers, { desc = 'registers ' })
vim.keymap.set('n', '<leader>ts', tb.spell_suggest, { desc = 'spell suggest ' })
vim.keymap.set('n', '<leader>tS', tb.search_history, { desc = 'search history ' })
vim.keymap.set('n', '<leader>tt', tb.treesitter, { desc = 'treesitter ' })
vim.keymap.set('n', '<leader>tT', tb.tags, { desc = 'tags ' })
vim.keymap.set('n', '<leader>tv', tb.vim_options, { desc = 'vim options ' })

vim.keymap.set('n', '<leader>uc', "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", { desc = 'colorscheme ' })
vim.keymap.set('n', '<leader>ut', "<cmd>TransparentToggle<cr>", { desc = 'Transparent Toggle' })

vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
vim.keymap.set("v", "<leader>x", "<cmd>'<,'>.lua<CR>", { desc = "Execute the selection" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })



local wk = require("which-key")
wk.add({
  mode = { "n", "v", },
  { "<leader>b", group = " 󰱿 Buffer" },
  { "<leader>f", group = "  Find" },
  { "<leader>g", group = "  Git" },
  { "<leader>h", group = "  Help" },
  { "<leader>l", group = "   LSP" },
  { "<leader>t", group = "  Telescope" },
  { "<leader>u", group = "   UI" },
})
--]]

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
