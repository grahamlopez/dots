-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/keymaps.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--[[
    These are the keymaps I have carried around for a while
    Keymaps for better default experience
    See `:help vim.keymap.set()`
    for modes, see `:help map-modes`

    To see mappings:
    - :help [keys] for built-in keymappings
    - :map [keys] for user-defined keymappings (with file:line location of defn)
    - :Telescope keymaps shows a searchable list of user-defined maps
      - would love to select the element and be taken to its definition
      - I can trigger this in any mode, but:
        1. it should only show me mappings for that mode
        2. it should show all mappings for that mode
    use 'c-v [key sequence]' to input a literal keypress involving the control key
    RFE: I would still like a unified way to see all keymappings for any given situation/mode
--]]

-- A more type-generic function for toggling values
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

-- A function to quit without saving the session (but save files)
vim.api.nvim_create_user_command("WQ", function()
  require("persistence").stop()
  vim.cmd("xa") -- alias for ":wqa"
end, { desc = "save and quit without saving session", nargs = 0 })

-- A function and keymapping to toggle colorcolum
vim.api.nvim_create_user_command("ToggleColorColumn", function()
  vim_opt_toggle("colorcolumn", "+1", "", "colorcolumn")
end, { desc = "toggle the colorcolumn at textwidth", nargs = 0 })

vim.g.saved_rnu = vim.o.relativenumber
vim.g.current_picker = "telescope"
vim.b.enable_autoformat = false
vim.g.enable_autoformat = false
vim.b.enable_only_firstcol_fold = false

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

local function pick_fns(telescope_fn, snacks_fn)
  return function()
    if vim.g.current_picker == "telescope" then
      telescope_fn()
    else
      snacks_fn()
    end
  end
end

-- WHICHKEY
local tb = require("telescope.builtin")
local sp = require("snacks").picker
local wk = require("which-key")

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
  { "<leader>t", group = "Todos" },
  { "<leader>u", group = "UI" },
})

-- stylua: ignore start
--
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true }) -- disable space in n,v
vim.keymap.set({ "n" }, "<esc>", ":noh<cr>", { silent = true }) -- cancel highlighting
vim.keymap.set("n", "<c-e>", "5<c-e>", { silent = true }) -- jumbo scrolling
vim.keymap.set("n", "<c-y>", "5<c-y>", { silent = true }) -- jumbo scrolling
vim.keymap.set( "n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true }) -- deal with line wrap
vim.keymap.set( "n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true }) -- deal with line wrap
vim.keymap.set("c", "vh", "vert help ", { noremap = true }) -- help in vertical split
-- must be a function to evaluate each time the keybinding is used instead of
-- only at startup
vim.keymap.set( "c", "CD", function() return "lcd " .. vim.fn.expand("%:p:h") end, { expr = true, desc = "change dir command" })
vim.keymap.set("i", "<c-l>", "<c-o>l", { silent = true }) -- move to the right right in insert mode
vim.keymap.set("v", "<", "<gv") -- Stay in indent mode
vim.keymap.set("v", ">", ">gv") -- Stay in indent mode

-- NON-LEADER
vim.keymap.set("n", "<c-f>", pick("current_buffer_fuzzy_find", "lines"), { desc = "find in buffer" })
vim.keymap.set("n", "<c-g>", pick("live_grep", "grep"), { desc = "grep current dir" })
vim.keymap.set({"n", "i", "v", "c", "o"}, "<M-k>", pick("keymaps", "keymaps"), { desc = "keymaps" })
-- RFE: would be cool to add popup git hunk diffs to 'K' as well
vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { desc = "Peek (UFO Fold, lsp.buf.hover(), etc.)" })

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
vim.keymap.set("n", "<leader>/", pick("live_grep", "grep"), { desc = "grep current dir" })
vim.keymap.set("n", "<leader>*", pick("grep_string", "grep_word"), { desc = "grep cwd for word under cursor" })
vim.keymap.set("n", "<leader>,", pick("buffers", "buffers"), { desc = "buffers" })
vim.keymap.set("n", "<leader>:", pick("command_history", "command_history"), { desc = "command history" })
vim.keymap.set({ "n", "v" }, "<leader>n", function() sp.notifications() end, { desc = "notification history" })
vim.keymap.set("n", "<leader><c-o>", pick("find_files", "files"), { desc = "open files" })
vim.keymap.set("n", "<leader><c-w>", "<cmd>b#<bar>bd#<cr>", { desc = "delete buffer" }) -- delete buffer - preserve window

-- APPS and AI
-- IDEA: terminal, lazygit, outline, file explorer, <c-z> trigger ai completion
vim.keymap.set('n', "<leader>aa", "<cmd>AerialToggle<cr>", { desc = "toggle aerial" })
vim.keymap.set("n", "<leader>aD", "cmd>PrtChatDelete<cr>", { desc = "delete chat file" })
vim.keymap.set("n", "<leader>ae", function() require("snacks").explorer() end, { desc = "file explorer" })
vim.keymap.set("n", "<leader>af", "<cmd>PrtChatFinder<cr>", { desc = "parrot chat finder" })
vim.keymap.set('n', "<leader>am", "<cmd>PrtModel<cr>", { desc = "select ai model" })
vim.keymap.set('n', "<leader>an", "<cmd>PrtChatNew<cr>", { desc = "new parrot chat" })
vim.keymap.set('n', "<leader>ao", "<cmd>Outline<cr>", { desc = "toggle outline" })
vim.keymap.set({ 'n', 'v' }, "<leader>ap", "<cmd>PrtChatPaste<cr>", { desc = "paste into parrot chat" })
vim.keymap.set('n', "<leader>aP", "<cmd>PrtProvider<cr>", { desc = "select ai provider" })
vim.keymap.set('n', "<leader>as", "<cmd>PrtStop<cr>", { desc = "stop ai response" })
vim.keymap.set('n', "<leader>at", "<cmd>PrtChatToggle<cr>", { desc = "toggle parrot chat" })
vim.keymap.set('n', "<leader>aT", "<cmd>PrtChatRespond<cr>", { desc = "trigger ai chat response" })
-- TODO: snacks explorer: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#explorer
--                      : https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md

-- BUFFERS
vim.keymap.set("n", "<leader>bb", pick("buffers", "buffers"), { desc = "buffer list" })
vim.keymap.set("n", "<leader>bd", "<cmd>b#<bar>bd#<cr>", { desc = "delete buffer" }) -- delete buffer - preserve window

-- GIT
local gitsigns = require('gitsigns')
-- https://github.com/nvimtools/hydra.nvim/wiki/Git
vim.keymap.set("n", "<leader>gg", function() require("snacks").lazygit() end, { desc = "lazygit" })
-- Navigation
vim.keymap.set('n', '<leader>gn', function()
  if vim.wo.diff then
    vim.cmd.normal({']c', bang = true})
  else
    gitsigns.nav_hunk('next')
  end
end, { desc = "next hunk" })

vim.keymap.set('n', '<leader>gp', function()
  if vim.wo.diff then
    vim.cmd.normal({'[c', bang = true})
  else
    gitsigns.nav_hunk('prev')
  end
end, { desc = "previous hunk" })
wk.add({ mode = { "n", "v" }, { "<leader>gh", group = "hunk actions" }, })
vim.keymap.set('n', '<leader>ghs', gitsigns.stage_hunk, { desc = "stage" })
vim.keymap.set('n', '<leader>ghr', gitsigns.reset_hunk, { desc = "reset" })
vim.keymap.set('v', '<leader>ghs', function() gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, { desc = "stage" })
vim.keymap.set('v', '<leader>ghr', function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, { desc = "reset" })
vim.keymap.set('n', '<leader>ghS', gitsigns.stage_buffer, { desc = "stage buffer" })
vim.keymap.set('n', '<leader>ghR', gitsigns.reset_buffer, { desc = "reset buffer" })
vim.keymap.set('n', '<leader>ghp', gitsigns.preview_hunk, { desc = "preview (popup)" })
vim.keymap.set('n', '<leader>ghi', gitsigns.preview_hunk_inline, { desc = "preview (inline)" })
vim.keymap.set('n', '<leader>ghb', function() gitsigns.blame_line({ full = true }) end, { desc = "blame line" })
vim.keymap.set('n', '<leader>ghd', gitsigns.diffthis, { desc = "diff (index)" })
vim.keymap.set('n', '<leader>ghq', gitsigns.setqflist, { desc = "set quickfix (buffer)" })
vim.keymap.set('n', '<leader>ghQ', function() gitsigns.setqflist('all') end, { desc = "set quickfix (all)" })
-- vim.keymap.set('n', '<leader>gsh', sp.git_diff, { desc = "snacks git picker hunks" })
-- vim.keymap.set('n', '<leader>gsh', tb.git_status, { desc = "telescope git picker hunks" })
vim.keymap.set('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = "toggle line blame" })
vim.keymap.set('n', '<leader>gtw', gitsigns.toggle_word_diff, { desc = "toggle word diff" })
vim.keymap.set({'o', 'x'}, 'ih', gitsigns.select_hunk) -- Text object

-- HELP
vim.keymap.set("n", "<leader>h*", pick_fns(
  function() require("telescope.builtin").help_tags({ default_text = vim.fn.expand("<cword>") }) end,
  function()
      require("snacks.picker").help()
      vim.schedule(function() vim.api.nvim_feedkeys(vim.fn.expand("<cword>"), "i", false) end)
  end), { desc = "help for cword" })
vim.keymap.set("n", "<leader>hh", pick("help_tags", "help"), { desc = "help" })
vim.keymap.set("n", "<leader>hm", pick("man_pages", "man"), { desc = "man pages" }) -- FIXME: nothing happens?
vim.keymap.set("n", "<leader>hM", pick_fns(
  function() require("telescope.builtin").man_pages({ default_text = vim.fn.expand("<cword>") }) end,
  function()
      require("snacks.picker").man()
      vim.schedule(function() vim.api.nvim_feedkeys(vim.fn.expand("<cword>"), "i", false) end)
  end), { desc = "man page for cword" })
vim.keymap.set("n", "<leader>hk", pick("keymaps", "keymaps"), { desc = "keymaps" })
vim.keymap.set("n", "<leader>hK", "<cmd>WhichKey<cr>", { desc = "which-key" })

-- LSP
vim.keymap.set("n", "<leader>l,", function() sp.lsp_config() end, { desc = "LSP config" })
-- QUESTION: are there other actions that can be enabled besides disabling the diagnostics
vim.keymap.set("n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "LSP code actions" })
vim.keymap.set("n", "<leader>lc", tb.lsp_incoming_calls, { desc = "LSP incoming calls" })
vim.keymap.set("n", "<leader>lC", tb.lsp_outgoing_calls, { desc = "LSP outgoing calls" })
vim.keymap.set("n", "<leader>ld", pick("lsp_definitions", "lsp_definitions"), { desc = "LSP definitions" })
vim.keymap.set("n", "<leader>lD", function() sp.lsp_declarations() end, { desc = "LSP declarations" })
-- FIXME: cannot format a visual selection except with explicit ":lua ..." command
vim.keymap.set({ "n", "v" }, "<leader>lf", function() require("conform").format( { async = true } ) end, { desc = "format (conform)" })
vim.keymap.set('n', '<leader>lF', "<cmd>lua vim.lsp.buf.format({async = true})<cr>", { desc = "format (vim)" })
vim.keymap.set("n", "<leader>li", pick("lsp_implementations", "lsp_implementations"), { desc = "LSP implementations" })
vim.keymap.set("n", "<leader>lr", pick("lsp_references", "lsp_references"), { desc = "LSP references" })
vim.keymap.set("n", "<leader>ls", pick("lsp_document_symbols", "lsp_symbols"), { desc = "LSP document symbols" })
vim.keymap.set("n", "<leader>lS", pick("lsp_workspace_symbols", "lsp_workspace_symbols"), { desc = "LSP workspace symbols" })
vim.keymap.set("n", "<leader>lt", pick("lsp_type_definitions", "lsp_type_definitions"), { desc = "LSP type definitions" })
vim.keymap.set("n", "<leader>lw", pick("diagnostics", "diagnostics"), { desc = "LSP diagnostics (warnings)" })
vim.keymap.set("n", '<leader>lWb', function() sp.diagnostics_buffer() end, { desc = "buffer diagnostics" })
vim.keymap.set("n", '<leader>lWf', function() vim.diagnostic.open_float() end, { desc = "open diagnostics float" })

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
vim.keymap.set("n", '<leader>sA', "<cmd>PrtChatFinder<cr>", { desc = "parrot chat finder" })
vim.keymap.set("n", "<leader>sb", pick("buffers", "buffers"), { desc = "buffers" })
vim.keymap.set('n', '<leader>sc', pick("commands", "commands"), { desc = 'find commands' })
vim.keymap.set("n", '<leader>sC', pick("command_history", "command_history"), { desc = "command_history" })
vim.keymap.set("n", "<leader>sf", pick("find_files", "files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>sF", tb.filetypes, { desc = "file types" })
vim.keymap.set("n", "<leader>sg", pick("live_grep", "grep"), { desc = "grep current dir" })
 -- QUESTION: there seems to be a big difference between the telescope 'help_tags' and snacks 'help' sources
vim.keymap.set("n", "<leader>sh", pick("help_tags", "help"), { desc = "help" })
vim.keymap.set("n", "<leader>sH", pick("highlights", "highlights"), { desc = "highlights" })
vim.keymap.set("n", "<leader>si", pick("symbols", "icons"), { desc = "icons" })
vim.keymap.set("n", "<leader>sj", pick("jumplist", "jumps"), { desc = "jump list" })
vim.keymap.set("n", "<leader>sk", pick("keymaps", "keymaps"), { desc = "keymaps" })
vim.keymap.set("n", "<leader>sl", pick("loclist", "loclist"), { desc = "location list" })
vim.keymap.set("n", "<leader>sm", pick("man_pages", "man"), { desc = "man pages" })
vim.keymap.set("n", "<leader>sM", pick("marks", "marks"), { desc = "marks" })
vim.keymap.set('n', "<leader>sn", pick_fns(
  function() tb.find_files({ cwd = vim.fn.stdpath("config") }) end,
  function() sp.files({ cwd = vim.fn.stdpath("config") }) end),
  { desc = 'nvim config files' })
vim.keymap.set('n', '<leader>sN', pick_fns(
  function() tb.live_grep({ cwd = vim.fn.stdpath("config") }) end,
  function() sp.grep({ dirs = { vim.fn.stdpath("config") }}) end),
  { desc = 'nvim config grep' })
vim.keymap.set("n", "<leader>sp", function() sp.lazy({ pattern = "" }) end, { desc = "plugin spec" })
vim.keymap.set("n", "<leader>sP", function() sp.projects() end, { desc = "projects" })
vim.keymap.set("n", "<leader>sq", tb.quickfixhistory, { desc = "quickfix history" })
vim.keymap.set("n", "<leader>sr", pick("oldfiles", "recent"), { desc = "recent files" })
vim.keymap.set("n", '<leader>sR', function() sp.resume() end, { desc = "resume" })
vim.keymap.set("n", "<leader>ss", tb.spell_suggest, { desc = "spell suggest" })
vim.keymap.set("n", '<leader>sS', pick("search_history", "search_history"), { desc = "search history" })
vim.keymap.set("n", "<leader>st", pick_fns(
  function() vim.cmd("TodoTelescope") end,
  function() require("snacks").picker.todo_comments() end),
  { desc = "search todos" })
vim.keymap.set("n", "<leader>sT", tb.treesitter, { desc = "treesitter" })
vim.keymap.set("n", '<leader>su', function() sp.undo() end, { desc = "undo history" })
vim.keymap.set("n", "<leader>sv", tb.vim_options, { desc = "vim options" })
vim.keymap.set("n", "<leader>sw", pick("diagnostics", "diagnostics"), { desc = "LSP diagnostics (warnings)" })

-- TO-DO
vim.keymap.set("n", "<leader>tt", pick_fns(
  function() vim.cmd("TodoTelescope") end,
  function() require("snacks").picker.todo_comments() end), { desc = "search todos" })

-- UI
-- IDEA: something like a hydra might be more useful here:
-- https://github.com/nvimtools/hydra.nvim/wiki/Vim-Options
-- e.g. it can show the current value of the options
vim.keymap.set("n", "<leader>ua", function() vim.b.enable_autoformat = not vim.b.enable_autoformat end, { desc = "autoformat (buffer)" })
vim.keymap.set("n", "<leader>uA", function() vim.g.enable_autoformat = not vim.g.enable_autoformat end, { desc = "autoformat (global)" })
vim.keymap.set("n", "<leader>uc", function() vim_opt_toggle('colorcolumn', '+1', '', 'colorcolumn') end,
  { desc = "ColorColumn Toggle" })
vim.keymap.set("n", '<leader>uC', pick_fns(
  function() require'telescope.builtin'.colorscheme( { enable_preview = true } ) end,
  function() sp.colorschemes() end),
  { desc = "colorscheme" })
vim.keymap.set('n', '<leader>ud', function()
                vim.diagnostic.enable(not vim.diagnostic.is_enabled(), { bufnr = 0 }) end,
                { desc = "Toggle diagnostics (current buffer)" })
vim.keymap.set('n', '<leader>uD', function()
                vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end,
                { desc = "Toggle diagnostics (global)" })
vim.keymap.set("n", "<leader>uf", function() vim.b.enable_only_firstcol_fold = not vim.b.enable_only_firstcol_fold end,
                { desc = "toggle firscol fold" })
vim.keymap.set("n", "<leader>ul", function() vim.o.cursorline = not vim.o.cursorline end, { desc = "cursorline" })
vim.keymap.set("n", "<leader>um", "<cmd>RenderMarkdown buf_toggle<cr>", { desc = "markdown render (buffer)" })
vim.keymap.set("n", "<leader>uM", "<cmd>RenderMarkdown toggle<cr>", { desc = "markdown render (global)" })
vim.keymap.set("n", "<leader>un", function()
  if vim.o.number then
    vim.g.saved_rnu = vim.o.relativenumber
    vim.o.relativenumber = false
    vim.o.number = false
  else
    vim.o.number = true
    vim.o.relativenumber = vim.g.saved_rnu
  end
  end, { desc = "line numbers" })
vim.keymap.set("n", "<leader>uN", function() vim.o.relativenumber = not vim.o.relativenumber end, { desc = "relative numbers" })
vim.keymap.set("n", "<leader>up", "<cmd>TogglePicker<cr>", { desc = "Toggle Picker" })
vim.keymap.set("n", "<leader>ut", "<cmd>TransparentToggle<cr>", { desc = "Transparent Toggle" })
vim.keymap.set("n", "<leader>uw", function() vim.o.wrap = not vim.o.wrap end, { desc = "visual line wrap" })
vim.keymap.set("n", "<leader>uz", function() require("snacks").zen() end, { desc = "Zen mode" })
vim.keymap.set("n", "<leader>uZ", function() require("snacks").zen.zoom() end, { desc = "Zen zoom" })

-- EXECUTE
vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
vim.keymap.set("v", "<leader>x", "<cmd>'<,'>.lua<CR>", { desc = "Execute the selection" })
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })

-- Folding
-- see nvim-ufo spec until it stabilizes
-- TODO: reset broken folds by closing the buffer and reopening, bonus for restoring window layout state
vim.keymap.set("n", "zh", "zM zv", { desc = "fold everywhere but here" })
vim.keymap.set("n", "h", function() -- h/l: pulled from nvim-origami
  local function normal(cmdStr) vim.cmd.normal({ cmdStr, bang = true }) end
  local count = vim.v.count1 -- saved as `normal` affects it
  for _ = 1, count, 1 do
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local textBeforeCursor = vim.api.nvim_get_current_line():sub(1, col)
    local onIndentOrFirstNonBlank = textBeforeCursor:match("^%s*$")
      and not vim.b.enable_only_firstcol_fold
    local firstChar = col == 0 and vim.b.enable_only_firstcol_fold
    if onIndentOrFirstNonBlank or firstChar then
      local wasFolded = pcall(normal, "zc")
      if not wasFolded then normal("h") end
    else
      normal("h")
    end
  end
end)
vim.keymap.set("n", "l", function()
  local function normal(cmdStr) vim.cmd.normal({ cmdStr, bang = true }) end
  local count = vim.v.count1 -- count needs to be saved due to `normal` affecting it
  for _ = 1, count, 1 do
    local isOnFold = vim.fn.foldclosed(".") > -1 ---@diagnostic disable-line: param-type-mismatch
    local action = isOnFold and "zo" or "l"
    pcall(normal, action)
  end
end)

--
-- stylua: ignore end

------------------------------------------------------------------------

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
