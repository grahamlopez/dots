
-- TODO: list {{{
--    TODO: FIXME: IDEA: TRACK: highlight and quickfix
--    transparent background
--    g-<c-g> to output word/line count in visual mode
-- }}}

-- Keybindings {{{
-- For modes, see `:help map-modes`
--     To see mappings:
--     - :help [keys] for built-in keymappings
--     - :map [keys] for user-defined keymappings (with file:line location of defn)

-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<leader>co", 
  function() vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua") end,
  { desc = "Edit Neovim config" })
vim.keymap.set('n', "<leader>cO", "<cmd>e ~/.config/nvim/init.lua<cr>", { desc = "main config open" })
vim.keymap.set({ "n" }, "<esc>", ":noh<cr>", { silent = true }) -- cancel highlighting
vim.keymap.set( "n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true }) -- deal with line wrap
vim.keymap.set( "n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true }) -- deal with line wrap

vim.keymap.set({ "n" }, "<leader>R", "<cmd>restart<cr>", { silent = true })
-- }}}

-- Options {{{
-- intro comments {{{
--[[
    These are some options that I've been carring around
    See :help vim.o and :help vim.opt
    and Vhyrro's YT vid: https://www.youtube.com/watch?v=Cp0iap9u29c&t=334s

    each table can contain both variables and/or options. variables are essentially
    "scoped" to a buffer, window, tab, or globally. Options may apply to one of
    these but not another. Note that 'id' numbers are optional, and default to
    the current buffer/window/tab

    variables         options
    ---------         ---------
    vim.b[id]         vim.bo[id]
    vim.w[id]         vim.wo[id]
    vim.t[id]         vim.to[id]
    vim.g             vim.o
                      vim.opt
                      vim.opt_local
                      vim.opt_global

    'vim.o' automatically detects the scope(s) of an option and uses it. If the
    option is only local or only global, sets that option. If the option is
    global-local, sets both versions of the variable. Only returns the bare
    variable; not helper functions.

    'vim.opt' will set both _global and _local versions, or whichever one is
    available if it isn't a global-local variable.

    Note that for checking option values (e.g. if vim.o[pt].background == "dark")
    that vim.o.* returns the option value as a Lua primitive, while vim.opt.*
    treats each option as a special object (metatable) with methods for list
    manipulation and advanced operations, such as vim.opt.background:get().

    ':set all' to see all possible settings and their current values
    ':help options' to get to the options part of the manual
--]]
-- }}}

-- General settings {{{
vim.opt.undofile = true -- Persistent undo
-- vim.opt.backup = false -- No backup files
-- vim.opt.writebackup = false -- No backup before overwriting
-- vim.opt.swapfile = false -- No swap files
vim.opt.hidden = true -- Allow hidden buffers
vim.opt.autoread = true -- Auto-read changed files
vim.opt.autowrite = true -- Auto-write before running commands
vim.opt.history = 1000 -- More command history
vim.opt.virtualedit = "block"
-- Performance optimizations
vim.loader.enable() -- Enable faster Lua module loading
vim.opt.updatetime = 250 -- Faster completion (4000ms default)
vim.opt.timeoutlen = 300 -- Faster which-key popup
vim.opt.lazyredraw = true -- Don't redraw during macros
-- opt.regexpengine = 1 -- Use old regex engine (faster for some patterns)
-- vim.opt.mouse = "nv" -- Disable mouse for speed
vim.opt.ttyfast = true -- Fast terminal connection
-- Disable some providers for faster startup
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python_provider = 0
-- Keep Python3 provider for some plugins that need it
-- vim.g.loaded_python3_provider = 0
-- }}}

-- Clipboard {{{
vim.opt.clipboard:append { "unnamed", "unnamedplus" } -- requires wl-clipboard
-- Configure clipboard for different environments
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end
-- }}}

-- Search settings {{{
vim.opt.hlsearch = true -- Set highlight on search
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
vim.opt.inccommand = "split"
vim.opt.shortmess:append("c")
-- }}}

-- Appearance {{{
vim.opt.termguicolors = true -- needs terminal support (most do)
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "number"
vim.opt.colorcolumn = ""
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5 -- Keep 8 columns left/right of cursor
vim.opt.pumheight = 15 -- Maximum items in popup menu
vim.opt.pumblend = 10 -- Popup menu transparency
vim.opt.winheight = 5
vim.opt.winminheight = 5
vim.opt.winwidth = 5
vim.opt.laststatus = 3
vim.opt.winminwidth = 5
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.diffopt:append("linematch:60") -- Better diffs
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "○",
  extends = "▸",
  precedes = "◂",
}
-- }}}

-- Indentation and formatting {{{
-- see also conform.nvim settings
-- vim.opt.formatoptions -= t -- disable wrap as you type
vim.opt.tabstop = 2 -- Tab width
vim.opt.shiftwidth = 2 -- Indent width
vim.opt.softtabstop = 2 -- Soft tab width
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Smart autoindenting
vim.opt.autoindent = true -- Copy indent from current line
vim.opt.breakindent = true -- Maintain indent when wrapping
vim.opt.wrap = false -- Don't wrap lines
vim.opt.linebreak = true -- Break at word boundaries if wrap enabled
vim.opt.textwidth = 80 -- Text width for formatting
-- }}}

-- Completion {{{
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
vim.opt.wildmode = "longest:full,full" -- Command completion mode
vim.opt.wildignore:append({ "*.o", "*.obj", ".git", "node_modules", "*.pyc" })
-- }}}

-- Folding {{{
-- IDEA: Big folding list:
--    toggle with <cr>
--    better navigation (zk, zj, [z, ]z)
--    - relative fold labeling for jumping with e.g. '<num>zj'
--      (this is already kinda there with foldcolumn=1 enabled
--    preserve folds across sessions
--    "focused folded" mode where I navigate to a location (via 'n/N' scrolling through
--      search results, pufo preview, from a picker grep, etc.) and that location is
--      unfolded, but everything else remains folded or is refolded as needed
--    lua block comments
--    what can be done about fold debugging e.g. showing fold locations, etc.?
--    remove need to close+re-open file when folds get messed up from just normal editing
--    e.g. subheadings get messed up when removing list items from top-level heading in markdown files
vim.opt.foldmethod = "expr" -- Use expression folding
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- TreeSitter folding
vim.opt.foldlevel = 99 -- Start with all folds open
vim.opt.foldenable = true -- Enable folding
vim.opt.foldcolumn = "1" -- enable minimal foldcolumn for mouse interaction
vim.opt.fillchars:append({ fold = " " })

-- vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()" -- TreeSitter fold text with syntax highlighting
-- vim.opt.foldtext = "v:lua.custom_foldtext()" -- TreeSitter fold text with syntax highlighting
-- _G.custom_foldtext = function()
--   local fs = vim.v.foldstart
--   local fe = vim.v.foldend
--   local level = vim.v.foldlevel
--   local dashes = ("+"):rep(level) .. "-- "
--   local line_count = fe - fs + 1
--   local first_line = vim.fn.getline(fs)
--   -- Clean up the line (remove leading whitespace, markers, etc.)
--   local clean_line = first_line:gsub("^%s*", ""):gsub("^[/*]+%s*", "")
--   return string.format("%s%d lines: %s ", dashes, line_count, clean_line)
-- end
-- }}}

-- Spell checking {{{
vim.opt.spell = false
vim.opt.spelllang = { "en_us" }
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
--- }}}

-- Session options {{{
vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "folds",
  "help",
  "tabpages",
  "winsize",
  "winpos",
  "terminal",
  "globals",
}
-- vim.opt.sessionoptions:append('globals') -- part of what's needed to preserve bufferline ordering
-- }}}
-- }}}

-- Filetype specifics {{{
-- init.lua {{{
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "init.lua",
  callback = function()
    vim.opt_local.foldmethod = "marker"
    vim.opt_local.foldmarker = "{{{,}}}"
    vim.opt_local.foldlevel = 0
  end,
})
-- }}}
-- }}}
vim.keymap.set({ "n" }, "<c-h>", "<cmd>restart<cr>", { silent = true })

--[[ IDEA: big markdown ideas list
-- list of suggestions
--  https://mambusskruj.github.io/posts/pub-neovim-for-markdown/#syntax-highlights-and-conceals

    - https://github.com/iwe-org/iwe
    - https://github.com/jakewvincent/mkdnflow.nvim
    - previewing:
      - synced external preview
    - table of contents: markdown-toc, https://youtu.be/BVyrXsZ_ViA
    - url linking improvements
      - fast entry
        - paste from clipboard with prompt for link title
          - or else a snippet
        - paste from clipboard in visual mode
        - shortcut to title the url under the cursor
      - use TOC to jump/navigate
    - filetype changes
      - textwidth (e.g. 100, 120?)
        - can this be set within specific files, e.g. for prose vs. notes differences?
    - table input and manipulation
    - image support
    - A couple of videos to start ideas:
      - <https://www.youtube.com/watch?v=DgKI4hZ4EEI>
      - <https://linkarzu.com/posts/neovim/markdown-setup-2025/>
    - other ideas:
      - easier bolding etc. with mini.surround and/or keymaps
      - better bullet lists: https://github.com/bullets-vim/bullets.vim
--]]
