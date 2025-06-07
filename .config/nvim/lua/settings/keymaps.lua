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

-- quicker change-directory
vim.keymap.set("c", "CD", "lcd " .. vim.fn.expand("%:p:h"), { desc = "change dir command" })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- or another way
-- vim.keymap.set({ "n", "x" }, "j", "gj", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "x" }, "k", "gk", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>w", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", { noremap = true, silent = true })

-- move the right right in insert mode
vim.keymap.set("i", "<c-l>", "<c-o>l", { silent = true })

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
vim.api.nvim_create_user_command("ToggleColorColumn", function()
  vim_opt_toggle("colorcolumn", "+1", "", "colorcolumn")
end, { desc = "toggle the colorcolumn at textwidth", nargs = 0 })

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
local tb = require("telescope.builtin")
local sp = require("snacks").picker
local wk = require("which-key")

vim.g.current_picker = "telescope"

vim.api.nvim_create_user_command("TogglePicker", function()
  if vim.g.current_picker == "telescope" then
    vim.g.current_picker = "snacks"
    vim.notify("Switched to Snacks picker")
  else
    vim.g.current_picker = "telescope"
    vim.notify("Switched to Telescope picker")
  end
end, { desc = "toggle the picker backend", nargs = 0 })

local function pick(telescope_fn, snacks_fn)
  return function()
    if vim.g.current_picker == "telescope" then
      require("telescope.builtin")[telescope_fn]()
    else
      require("snacks.picker")[snacks_fn]()
    end
  end
end

local function pick_cword(telescope_fn, snacks_fn)
  return function()
    if vim.g.current_picker == "telescope" then
      require("telescope.builtin")[telescope_fn]({ default_text = vim.fn.expand("<cword>") })
    else
      require("snacks.picker")[snacks_fn]()
      vim.schedule(function()
        vim.api.nvim_feedkeys(vim.fn.expand("<cword>"), "i", false)
      end)
    end
  end
end

-- WHICHKEY
wk.add({
  mode = { "n", "v" },
  { "<leader>a", group = "AI/Apps" },
  { "<leader>b", group = "Buffer" },
  { "<leader>f", group = "Find" },
  { "<leader>g", group = "Git" },
  { "<leader>h", group = "Help" },
  { "<leader>l", group = "LSP" },
  { "<leader>q", group = "Session/Quit" },
  { "<leader>s", group = "Search" },
  { "<leader>u", group = "UI" },
})

-- FIXME why is stylua ignore not working?

-- stylua: ignore start

-- NON-LEADER
vim.keymap.set("n", "<c-f>", pick("current_buffer_fuzzy_find", "lines"), { desc = "find in buffer" })
vim.keymap.set("n", "<c-g>", pick("live_grep", "grep"), { desc = "grep" })
vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })
vim.keymap.set({ "x", "o" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
vim.keymap.set("c", "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })

vim.keymap.set("n", "<c-b>", pick("buffers", "buffers"), { desc = "buffers" })
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
vim.keymap.set("n", "<leader>/", pick("live_grep", "grep"), { desc = "grep" })
vim.keymap.set("n", "<leader>*", pick("grep_string", "grep_word"), { desc = "grep cwd for word under cursor" })
vim.keymap.set("n", "<leader>,", pick("buffers", "buffers"), { desc = "buffers" })
vim.keymap.set("n", "<leader>:", pick("command_history", "command_history"), { desc = "command history" })
vim.keymap.set({ "n", "v" }, "<leader>n", function() sp.notifications() end, { desc = "notification history" })

-- APPS and AI
-- TODO terminal, lazygit, outline, file explorer
-- c-z trigger ai completion
vim.keymap.set('n', "<leader>aa", "<cmd>AerialToggle<cr>", { desc = "toggle aerial" })
vim.keymap.set("n", "<leader>aD", "cmd>PrtChatDelete<cr>", { desc = "delete chat file" })
vim.keymap.set("n", "<leader>ae", function() require("snacks").explorer() end, { desc = "file explorer" })
vim.keymap.set("n", "<leader>af", "cmd>PrtChatFinder<cr>", { desc = "parrot chat finder" })
vim.keymap.set('n', "<leader>am", "<cmd>PrtModel<cr>", { desc = "select ai model" })
vim.keymap.set('n', "<leader>an", "<cmd>PrtChatNew<cr>", { desc = "new parrot chat" })
vim.keymap.set('n', "<leader>ao", "<cmd>Outline<cr>", { desc = "toggle outline" })
vim.keymap.set({ 'n', 'v' }, "<leader>ap", "<cmd>PrtChatPaste<cr>", { desc = "paste into parrot chat" })
vim.keymap.set('n', "<leader>aP", "<cmd>PrtProvider<cr>", { desc = "select ai provider" })
vim.keymap.set('n', "<leader>as", "<cmd>PrtStop<cr>", { desc = "stop ai response" })
vim.keymap.set('n', "<leader>at", "<cmd>PrtChatToggle<cr>", { desc = "toggle parrot chat" })
vim.keymap.set('n', "<leader>aT", "<cmd>PrtChatRespond<cr>", { desc = "trigger ai chat response" })

-- BUFFERS
vim.keymap.set("n", "<leader>bb", pick("buffers", "buffers"), { desc = "buffer list" })
-- delete buffer - preserve window (switch to alternate, "|" to chain, delete alternate)
-- FIXME this could be extended with "... | wshada | ..." to preserve marks
-- (cursor position), but can be an issue when using multiple instances
vim.keymap.set("n", "<leader>bd", "<cmd>b#<bar>bd#<cr>", { desc = "delete buffer" })

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
-- vim.keymap.set('n', '<leader>gb', tb.git_branches, { desc = ' git branches ' })
-- vim.keymap.set('v', '<leader>gc', tb.git_bcommits, { desc = 'git commits (range) ' })
-- vim.keymap.set('n', '<leader>gc', tb.git_bcommits, { desc = 'git commits (buffer) ' })
-- vim.keymap.set('n', '<leader>gC', tb.git_commits, { desc = 'git commits (all) ' })
-- vim.keymap.set('n', '<leader>gs', tb.git_status, { desc = 'git status ' })
-- vim.keymap.set('n', '<leader>gS', tb.git_stash, { desc = 'git stash ' })

-- HELP
vim.keymap.set("n", "<leader>h*", pick_cword("help_tags", "help"), { desc = "help for cword" })
vim.keymap.set("n", "<leader>hh", pick("help_tags", "help"), { desc = "help" })
vim.keymap.set("n", "<leader>hm", pick("man_pages", "man"), { desc = "man pages" }) -- FIXME nothing happens?
vim.keymap.set("n", "<leader>hM", pick_cword("man_pages", "man"), { desc = "man pages" })
vim.keymap.set("n", "<leader>hk", pick("keymaps", "keymaps"), { desc = "keymaps" })
vim.keymap.set("n", "<leader>hK", "<cmd>WhichKey<cr>", { desc = "which-key" })

-- LSP
vim.keymap.set("n", "<leader>l,", function() sp.lsp_config() end, { desc = "LSP config" })
vim.keymap.set("n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "LSP code actions" })
vim.keymap.set("n", "<leader>lc", tb.lsp_incoming_calls, { desc = "LSP incoming calls" })
vim.keymap.set("n", "<leader>lC", tb.lsp_outgoing_calls, { desc = "LSP outgoing calls" })
vim.keymap.set("n", "<leader>ld", pick("lsp_definitions", "lsp_definitions"), { desc = "LSP definitions" })
vim.keymap.set("n", "<leader>lD", function() sp.lsp_declarations() end, { desc = "LSP declarations" })
vim.keymap.set("n", "<leader>lf", function() require("conform").format({ async = true }) end,
  { desc = "format (conform)" })
vim.keymap.set('n', '<leader>lF', "<cmd>lua vim.lsp.buf.format({async = true})<cr>", { desc = "format (vim)" })
vim.keymap.set("n", "<leader>li", pick("lsp_implementations", "lsp_implementations"), { desc = "LSP implementations" })
vim.keymap.set("n", "<leader>lr", pick("lsp_references", "lsp_references"), { desc = "LSP references" })
vim.keymap.set("n", "<leader>ls", pick("lsp_document_symbols", "lsp_symbols"), { desc = "LSP document symbols" })
vim.keymap.set("n", "<leader>lS", pick("lsp_workspace_symbols", "lsp_workspace_symbols"),
  { desc = "LSP workspace symbols" })
vim.keymap.set("n", "<leader>lt", pick("lsp_type_definitions", "lsp_type_definitions"), { desc = "LSP type definitions" })
vim.keymap.set("n", "<leader>lw", pick("diagnostics", "diagnostics"), { desc = "LSP diagnostics (warnings)" })
vim.keymap.set("n", '<leader>lW', function() sp.diagnostics_buffer() end, { desc = "buffer diagnostics" })

-- SESSIONS
vim.keymap.set("n", "<c-s>", function() require("persistence").select() end, { desc = "Select Session" })
vim.keymap.set("n", "<leader>qr", function() require("persistence").load() end, { desc = "Restore Session" })
vim.keymap.set("n", "<leader>qs", function() require("persistence").select() end, { desc = "Select Session" })
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end,
  { desc = "Restore Last Session" })
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })

-- SEARCH
vim.keymap.set("n", "<leader>s/", pick("current_buffer_fuzzy_find", "lines"), { desc = "search in buffer" })
vim.keymap.set("n", '<leader>s"', pick("registers", "registers"), { desc = "registers" })
vim.keymap.set("n", '<leader>sa', pick("autocommands", "autocmds"), { desc = "autocommands" })
vim.keymap.set("n", '<leader>sA', "cmd>PrtChatFinder<cr>", { desc = "parrot chat finder" })
vim.keymap.set("n", "<leader>sb", pick("buffers", "buffers"), { desc = "buffers" })
vim.keymap.set('n', '<leader>sc', pick("commands", "commands"), { desc = 'find commands' })
vim.keymap.set("n", '<leader>sC', pick("command_history", "command_history"), { desc = "command_history" })
vim.keymap.set("n", "<leader>sf", pick("find_files", "files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>sF", tb.filetypes, { desc = "file types" })
vim.keymap.set("n", "<leader>sg", pick("live_grep", "grep"), { desc = "grep" })
vim.keymap.set("n", "<leader>sh", pick("help_tags", "help"), { desc = "help" })
vim.keymap.set("n", "<leader>sH", pick("highlights", "highlights"), { desc = "highlights" })
vim.keymap.set("n", "<leader>si", pick("symbols", "icons"), { desc = "icons" })
vim.keymap.set("n", "<leader>sj", pick("jumplist", "jumps"), { desc = "jump list" })
vim.keymap.set("n", "<leader>sk", pick("keymaps", "keymaps"), { desc = "jump list" })
vim.keymap.set("n", "<leader>sl", pick("loclist", "loclist"), { desc = "location list" })
vim.keymap.set("n", "<leader>sm", pick("marks", "marks"), { desc = "marks" })
vim.keymap.set("n", "<leader>sm", pick("man_pages", "man"), { desc = "man pages" })
vim.keymap.set('n', '<leader>sn', function() sp.files({ cwd = vim.fn.stdpath("config") }) end,
  { desc = 'nvim config files' })
vim.keymap.set("n", '<leader>sp', function() sp.lazy() end, { desc = "plugin spec" })
vim.keymap.set("n", "<leader>sP", function() sp.projects() end, { desc = "projects" })
vim.keymap.set("n", "<leader>sq", tb.quickfixhistory, { desc = "quickfix history" })
vim.keymap.set("n", "<leader>sr", pick("oldfiles", "recent"), { desc = "recent files" })
vim.keymap.set("n", '<leader>sR', function() sp.resume() end, { desc = "resume" })
vim.keymap.set("n", "<leader>ss", tb.spell_suggest, { desc = "spell suggest" })
vim.keymap.set("n", '<leader>sS', pick("search_history", "search_history"), { desc = "search history" })
vim.keymap.set("n", "<leader>st", tb.tags, { desc = "tags" })
vim.keymap.set("n", "<leader>sT", tb.treesitter, { desc = "treesitter" })
vim.keymap.set("n", '<leader>su', function() sp.undo() end, { desc = "undo history" })
vim.keymap.set("n", "<leader>sv", tb.vim_options, { desc = "vim options" })

-- TO-DO
vim.keymap.set("n", "<leader>tt", "<cmd>Telescope grep_string search=TODO<cr>", { desc = "Find TODO comments" })
vim.keymap.set("n", "<leader>tf", "<cmd>Telescope grep_string search=FIXME<cr>", { desc = "Find FIXME comments" })
vim.keymap.set("n", "<leader>ta", "<cmd>Telescope live_grep default_text=TODO|FIXME<cr>",
  { desc = "Find TODO and FIXME comments" })

-- UI
vim.keymap.set("n", "<leader>uc", function() vim_opt_toggle('colorcolumn', '+1', '', 'colorcolumn') end,
  { desc = "ColorColumn Toggle" })
vim.keymap.set("n", '<leader>uC', function() sp.colorschemes() end, { desc = "colorscheme" })
-- vim.keymap.set( "n", "<leader>uC", "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", { desc = "colorscheme" })
vim.keymap.set("n", "<leader>ul", function() vim.o.cursorline = not vim.o.cursorline end, { desc = "cursorline" })
-- FIXME: this should remove numbers even if relativenumber is active
vim.keymap.set("n", "<leader>un", function() vim.o.number = not vim.o.number end, { desc = "line numbers" })
vim.keymap.set("n", "<leader>uN", function() vim.o.relativenumber = not vim.o.relativenumber end,
  { desc = "relative numbers" })
vim.keymap.set("n", "<leader>up", "<cmd>TogglePicker<cr>", { desc = "Toggle Picker" })
-- TODO vim.keymap.set("n", "<leader>us", function() require("snacks").scroll.disable() end, { desc = "smooth scrolling" })
vim.keymap.set("n", "<leader>ut", "<cmd>TransparentToggle<cr>", { desc = "Transparent Toggle" })
vim.keymap.set("n", "<leader>uw", function() vim.o.wrap = not vim.o.wrap end, { desc = "visual line wrap" })
-- TODO how is this different than folke/zen-mode.nvim
vim.keymap.set("n", "<leader>uz", function() require("snacks").zen() end, { desc = "Zen mode" })
vim.keymap.set("n", "<leader>uZ", function() require("snacks").zen.zoom() end, { desc = "Zen zoom" })
-- TODO diagnostics
-- TODO indent guides
-- TODO gitsigns

-- EXECUTE
-- FIXME not sure how really useful these are
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
