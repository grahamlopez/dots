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
vim.keymap.set({ "n" }, "<esc>", ":noh<cr>", { silent = true })
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- jumbo scrolling
vim.keymap.set("n", "<c-e>", "5<c-e>", { silent = true })
vim.keymap.set("n", "<c-y>", "5<c-y>", { silent = true })

-- automatically open help in vertical split
vim.keymap.set("c", "vh", "vert help ", { noremap = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- or another way
-- vim.keymap.set({ "n", "x" }, "j", "gj", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "x" }, "k", "gk", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>w", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", { noremap = true, silent = true })

-- A generic function for toggling values. Seems a bit hacky FIXME
local function vim_opt_toggle(opt, on, off, name)
  local val = vim.opt[opt]:get()
  local is_off = false

  if type(val) == "boolean" then
    is_off = not val
  elseif type(val) == "string" then
    is_off = (val == off)
  elseif type(val) == "table" then
    is_off = (#val == 0) or (#val == 1 and val[1] == "")
  else
    is_off = (val == off)
  end

  if is_off then
    vim.opt[opt] = on
    vim.notify((name or opt) .. " Enabled")
  else
    vim.opt[opt] = off
    vim.notify((name or opt) .. " Disabled")
  end
end

-- A function and keymapping to toggle colorcolum
vim.api.nvim_create_user_command("Togglecolorcolumn", function()
  vim_opt_toggle("colorcolumn", "+1", "", "colorcolumn")
end, { desc = "toggle the colorcolumn at textwidth", nargs = 0 })

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
-- stylua: ignore start

-- first, some conveniences for use in the following mapping specs
local tb = require("telescope.builtin")
local sp = require("snacks").picker
local wk = require("which-key")

-- WHICHKEY
wk.add({
	mode = { "n", "v" },
	{ "<leader>b", group = "Buffer" },
	{ "<leader>f", group = "Find" },
	{ "<leader>g", group = "Git" },
	{ "<leader>h", group = "Help" },
	{ "<leader>l", group = "LSP" },
	{ "<leader>lv", group = "Vim" },
	{ "<leader>lt", group = "Telescope" },
	{ "<leader>q", group = "Session/Quit" },
	{ "<leader>s", group = "Search" },
	{ "<leader>st", group = "Telescope" },
	{ "<leader>u", group = "UI" },
})

-- NON-LEADER
vim.keymap.set("n", "<c-f>", function() sp.lines() end, { desc = "find in buffer" })
vim.keymap.set("n", "<c-g>", function() sp.grep() end, { desc = "grep" })
vim.keymap.set("n", "<leader>*", function() sp.grep_word() end, { desc = "grep cwd for word under cursor" })
vim.keymap.set({ "n", "x", "o"}, "s", function() require("flash").jump() end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o"}, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })
vim.keymap.set({ "x", "o"}, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
vim.keymap.set("c", "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })

vim.keymap.set("n", "<c-b>", function() sp.buffers() end, { desc = "buffers" })
vim.keymap.set('n', "<M-1>", "<cmd>BufferLineGoToBuffer 1<cr>", { desc = "goto visible buffer 1" })
vim.keymap.set('n', "<M-2>", "<cmd>BufferLineGoToBuffer 2<cr>", { desc = "goto visible buffer 2" })
vim.keymap.set('n', "<M-3>", "<cmd>BufferLineGoToBuffer 3<cr>", { desc = "goto visible buffer 3" })
vim.keymap.set('n', "<M-4>", "<cmd>BufferLineGoToBuffer 4<cr>", { desc = "goto visible buffer 4" })
vim.keymap.set('n', "<M-5>", "<cmd>BufferLineGoToBuffer 5<cr>", { desc = "goto visible buffer 5" })
vim.keymap.set('n', "<M-6>", "<cmd>BufferLineGoToBuffer 6<cr>", { desc = "goto visible buffer 6" })
vim.keymap.set('n', "<M-7>", "<cmd>BufferLineGoToBuffer 7<cr>", { desc = "goto visible buffer 7" })
vim.keymap.set('n', "<M-8>", "<cmd>BufferLineGoToBuffer 8<cr>", { desc = "goto visible buffer 8" })
vim.keymap.set('n', "<M-9>", "<cmd>BufferLineGoToBuffer 9<cr>", { desc = "goto visible buffer 9" })
vim.keymap.set('n', "<M-0>", "<cmd>BufferLineGoToBuffer 10<cr>", { desc = "goto visible buffer 10" })
vim.keymap.set('n', "<M-l>", "<c-^>", { desc = "edit last <c-^>" })
vim.keymap.set('n', "<c-n>", "<cmd>BufferLineCycleNext<cr>", { desc = "next visible buffer" })     -- try this to find conflicts
vim.keymap.set('n', "<c-p>", "<cmd>BufferLineCyclePrev<cr>", { desc = "previous visible buffer" }) -- try this to find conflicts
vim.keymap.set('n', "<M-L>", "<cmd>BufferLineMoveNext<cr>", { desc = "move buffer tab right" })
vim.keymap.set('n', "<M-H>", "<cmd>BufferLineMovePrev<cr>", { desc = "move buffer tab left" })

-- TOP LEVEL
vim.keymap.set("n", "<leader>/", function() sp.grep() end, { desc = "grep" })
vim.keymap.set("n", "<leader>,", function() sp.buffers() end, { desc = "buffers" })
vim.keymap.set("n", "<leader>:", function() sp.command_history() end, { desc = "command history" })
vim.keymap.set({ "n", "v" }, "<leader>n", function() sp.notifications() end, { desc = "notification history" })
vim.keymap.set( "n", "<leader>e", function() require("snacks").explorer() end, { desc = "file explorer" })

-- BUFFERS
vim.keymap.set("n", "<leader>bb", function() sp.buffers() end, { desc = "buffer list" })
-- delete buffer - preserve window (switch to alternate, "|" to chain, delete alternate)
-- FIXME this could be extended with "... | wshada | ..." to preserve marks
-- (cursor position), but can be an issue when using multiple instances
vim.keymap.set("n", "<leader>bd", "<cmd>b#<bar>bd#<cr>", { desc = "delete buffer" })

-- quicker change-directory
vim.keymap.set("n", "<leader>cd", function()
  local dir = vim.fn.expand("%:p:h")
  vim.api.nvim_feedkeys(":" .. "lcd " .. dir, "n", false)
end,{ desc = "Pre-fill :cd with current buffer path" })

-- FINDS
vim.keymap.set("n", "<leader>fb", function() sp.buffers() end, { desc = "buffers" })
vim.keymap.set('n', '<leader>fc', function() sp.files({ cwd = vim.fn.stdpath("config") }) end, { desc = 'find config files' })
vim.keymap.set('n', '<leader>fC', function() sp.commands() end, { desc = 'find config files' })
vim.keymap.set("n", "<leader>ff", function() sp.smart() end, { desc = "find files (smart)" })
vim.keymap.set("n", "<leader>fF", function() sp.files() end, { desc = "find files" })
vim.keymap.set("n", "<leader>fg", function() sp.git_files() end, { desc = "live grep" })
vim.keymap.set("n", "<leader>fh", function() sp.help() end, { desc = "help" })
vim.keymap.set("n", "<leader>fp", function() sp.projects() end, { desc = "projects" })
vim.keymap.set("n", "<leader>fr", function() sp.recent() end, { desc = "recent" })

-- GIT - disabling these until I understand them
vim.keymap.set("n", "<leader>gg", function() require("snacks").lazygit() end, { desc = "lazygit" })
-- vim.keymap.set("n", "<leader>gb", function() sp.git_branches() end, { desc = "git branches search" })
-- vim.keymap.set({ "n", "v" }, "<leader>gB", function() require("snacks").gitbrowse() end, { desc = "open github" })
-- vim.keymap.set("n", "<leader>gd", function() sp.git_diff() end, { desc = "git diff search" })
-- vim.keymap.set("n", "<leader>gf", function() sp.git_log_file() end, { desc = "git logfile search" })
-- vim.keymap.set("v", "<leader>gl", function() sp.git_log() end, { desc = "git log search" })
-- vim.keymap.set("n", "<leader>gL", function() sp.git_log_line() end, { desc = "git log lines search" })
-- vim.keymap.set("n", "<leader>gs", function() sp.git_status() end, { desc = "git status search" })
-- vim.keymap.set("n", "<leader>gS", function() sp.git_stash() end, { desc = "git stash search" })

-- HELP
-- FIXME open help for word under cursor
-- vim.keymap.set("n", "<leader>h*", function() 
--   local keys = vim.api.nvim_replace_termcodes('<C-r><C-w>', true, false, true)
--   sp.help()
--   vim.wait(500, function() return false end)
--   vim.api.nvim_feedkeys(keys, 'n', false)
-- end, { desc = "help for cword" })
vim.keymap.set("n", "<leader>hth", tb.help_tags, { desc = "help" })
vim.keymap.set("n", "<leader>htk", tb.keymaps, { desc = "keymaps" })
vim.keymap.set("n", "<leader>htm", tb.man_pages, { desc = "man pages" })
vim.keymap.set("n", "<leader>hh", function() sp.help() end, { desc = "help" })
vim.keymap.set("n", "<leader>hm", function() sp.man() end, { desc = "man pages" })
vim.keymap.set("n", "<leader>hk", function() sp.keymaps() end, { desc = "keymaps" })
vim.keymap.set("n", "<leader>hw", "<cmd>WhichKey<cr>", { desc = "which-key" })

-- LSP
vim.keymap.set("n", "<leader>l,", function() sp.lsp_config() end, { desc = "LSP config" })
vim.keymap.set("n", "<leader>lc", tb.lsp_incoming_calls, { desc = "LSP incoming calls" })
vim.keymap.set("n", "<leader>lC", tb.lsp_outgoing_calls, { desc = "LSP outgoing calls" })
vim.keymap.set("n", "<leader>ld", function() sp.lsp_definitions() end, { desc = "LSP definitions" })
vim.keymap.set("n", "<leader>lD", function() sp.lsp_declarations() end, { desc = "LSP declarations" })
vim.keymap.set("n", "<leader>lf", function() require("conform").format({ async = true }) end, { desc = "Format" })
vim.keymap.set("n", "<leader>li", function() sp.lsp_implementations() end, { desc = "LSP implementations" })
vim.keymap.set("n", "<leader>lr", function() sp.lsp_references() end, { desc = "LSP references" })
vim.keymap.set("n", "<leader>ls", function() sp.lsp_symbols() end, { desc = "LSP document symbols" })
vim.keymap.set("n", "<leader>lS", function() sp.lsp_workspace_symbols() end, { desc = "LSP workspace symbols" })
vim.keymap.set("n", "<leader>lt", function() sp.lsp_type_definitions() end, { desc = "LSP type definitions" })
vim.keymap.set("n", "<leader>lw", function() sp.diagnostics() end, { desc = "LSP diagnostics (warnings)" })

vim.keymap.set("n", "<leader>lva", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "LSP code actions" })
vim.keymap.set('n', '<leader>lvf', "<cmd>lua vim.lsp.buf.format({async = true})<cr>", { desc = "Format" })

vim.keymap.set("n", "<leader>ltc", tb.lsp_incoming_calls, { desc = "LSP incoming calls" })
vim.keymap.set("n", "<leader>ltC", tb.lsp_outgoing_calls, { desc = "LSP outgoing calls" })
vim.keymap.set("n", "<leader>ltd", tb.lsp_definitions, { desc = "LSP definitions" })
vim.keymap.set("n", "<leader>lti", tb.lsp_implementations, { desc = "LSP implementations" })
vim.keymap.set("n", "<leader>ltr", tb.lsp_references, { desc = "LSP references" })
vim.keymap.set("n", "<leader>lts", tb.lsp_document_symbols, { desc = "LSP document symbols" })
vim.keymap.set("n", "<leader>ltS", tb.lsp_workspace_symbols, { desc = "LSP workspace symbols" })
vim.keymap.set("n", "<leader>ltt", tb.lsp_type_definitions, { desc = "LSP type definitions" })
vim.keymap.set("n", "<leader>ltw", tb.diagnostics, { desc = "LSP diagnostics (warnings)" })

-- SESSIONS
vim.keymap.set("n", "<c-s>", function() require("persistence").select() end, { desc = "Select Session" })
vim.keymap.set("n", "<leader>qr", function() require("persistence").load() end, { desc = "Restore Session" })
vim.keymap.set("n", "<leader>qs", function() require("persistence").select() end, { desc = "Select Session" })
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })

-- SEARCH
vim.keymap.set("n", '<leader>s/', function() sp.lines() end, { desc = "search current buffer" }) -- FIXME
vim.keymap.set("n", '<leader>s"', function() sp.registers() end, { desc = "registers" })
vim.keymap.set("n", '<leader>sa', function() sp.autocmds() end, { desc = "autocommands" })
vim.keymap.set("n", '<leader>sb', function() sp.buffers() end, { desc = "buffers" })
vim.keymap.set("n", '<leader>sc', function() sp.commands() end, { desc = "commands" })
vim.keymap.set("n", '<leader>sC', function() sp.command_history() end, { desc = "command_history" })
vim.keymap.set("n", "<leader>sg", function() sp.grep() end, { desc = "grep" })
vim.keymap.set("n", "<leader>sh", function() sp.help() end, { desc = "help" })
vim.keymap.set("n", "<leader>sH", function() sp.highlights() end, { desc = "highlights" })
vim.keymap.set("n", "<leader>si", function() sp.icons() end, { desc = "icons" })
vim.keymap.set("n", "<leader>sj", function() sp.jumps() end, { desc = "jump list" })
vim.keymap.set("n", "<leader>sk", function() sp.keymaps() end, { desc = "jump list" })
vim.keymap.set("n", "<leader>sl", function() sp.loclist() end, { desc = "location list" })
vim.keymap.set("n", "<leader>sm", function() sp.marks() end, { desc = "marks" })
vim.keymap.set("n", "<leader>sm", function() sp.man() end, { desc = "man pages" })
vim.keymap.set("n", "<leader>sq", function() sp.qflist() end, { desc = "quickfix" })
vim.keymap.set("n", '<leader>sd', function() sp.diagnostics() end, { desc = "diagnostics" })
vim.keymap.set("n", '<leader>sD', function() sp.diagnostics_buffer() end, { desc = "buffer diagnostics" })
vim.keymap.set("n", '<leader>sp', function() sp.lazy() end, { desc = "search for plugin spec" })
vim.keymap.set("n", '<leader>sR', function() sp.resume() end, { desc = "resume" })
vim.keymap.set("n", '<leader>sS', function() sp.search_history() end, { desc = "search history" })
-- vim.keymap.set("n", '<leader>sf', function() sp.todo_comments() end, { desc = "TODO" })
-- vim.keymap.set("n", '<leader>sF', function() sp.todo_comments({ keywords = { "TODO", "FIXME", }}) end, { desc = "TODO FIXME" })
vim.keymap.set("n", '<leader>su', function() sp.undo() end, { desc = "undo history" })

vim.keymap.set("n", '<leader>st/', tb.current_buffer_fuzzy_find, { desc = "current buffer fuzzy" })
vim.keymap.set("n", '<leader>st"', tb.registers, { desc = "registers" })
vim.keymap.set("n", '<leader>sta', tb.autocommands, { desc = "autocommands" })
vim.keymap.set("n", "<leader>stb", tb.buffers, { desc = "buffers" })
vim.keymap.set("n", "<leader>stc", tb.commands, { desc = "commands" })
vim.keymap.set("n", "<leader>stC", tb.command_history, { desc = "command history" })
vim.keymap.set("n", "<leader>sth", tb.help_tags, { desc = "help" })
vim.keymap.set("n", "<leader>stH", tb.highlights, { desc = "highlights" })
vim.keymap.set("n", "<leader>sti", tb.symbols, { desc = "icons" })
vim.keymap.set("n", "<leader>stj", tb.jumplist, { desc = "jump list" })
vim.keymap.set("n", "<leader>stk", tb.keymaps, { desc = "normal mode keymaps" })
vim.keymap.set("n", "<leader>stl", tb.loclist, { desc = "location list" })
vim.keymap.set("n", "<leader>stm", tb.marks, { desc = "marks" })
vim.keymap.set("n", "<leader>stM", tb.man_pages, { desc = "man pages" })
vim.keymap.set("n", "<leader>stf", tb.filetypes, { desc = "file types" })
vim.keymap.set("n", "<leader>sto", tb.oldfiles, { desc = "oldfiles" })
vim.keymap.set("n", "<leader>stQ", tb.quickfixhistory, { desc = "quickfix history" })
vim.keymap.set("n", "<leader>sts", tb.spell_suggest, { desc = "spell suggest" })
vim.keymap.set("n", "<leader>stS", tb.search_history, { desc = "search history" })
vim.keymap.set("n", "<leader>stt", tb.treesitter, { desc = "treesitter" })
vim.keymap.set("n", "<leader>stT", tb.tags, { desc = "tags" })
vim.keymap.set("n", "<leader>stv", tb.vim_options, { desc = "vim options" })

-- UI
-- vim.keymap.set("n", "<leader>uc", "<cmd>Togglecolorcolumn<cr>", { desc = "ColorColumn Toggle" })
vim.keymap.set("n", "<leader>uc", function() vim_opt_toggle('colorcolumn', '+1', '', 'colorcolumn') end, { desc = "ColorColumn Toggle" })
vim.keymap.set("n", '<leader>uC', function() sp.colorschemes() end, { desc = "colorscheme" })
-- vim.keymap.set( "n", "<leader>uC", "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", { desc = "colorscheme" })
vim.keymap.set("n", "<leader>ul", function() vim.o.cursorline = not vim.o.cursorline end, { desc = "cursorline" })
vim.keymap.set("n", "<leader>un", function() vim.o.number = not vim.o.number end, { desc = "line numbers" })
vim.keymap.set("n", "<leader>uN", function() vim.o.relativenumber = not vim.o.relativenumber end, { desc = "relative numbers" })
-- TODO vim.keymap.set("n", "<leader>us", function() require("snacks").scroll.disable() end, { desc = "smooth scrolling" })
vim.keymap.set("n", "<leader>ut", "<cmd>TransparentToggle<cr>", { desc = "Transparent Toggle" })
vim.keymap.set("n", "<leader>uw", function() vim.o.wrap = not vim.o.wrap end, { desc = "visual line wrap" })
vim.keymap.set("n", "<leader>uz", function() require("snacks").zen() end, { desc = "Zen mode" })
vim.keymap.set("n", "<leader>uZ", function() require("snacks").zen.zoom() end, { desc = "Zen zoom" })
-- TODO diagnostics
-- TODO indent guides

-- EXECUTE
vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
vim.keymap.set("v", "<leader>x", "<cmd>'<,'>.lua<CR>", { desc = "Execute the selection" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })

-- stylua: ignore end

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
