
-- TODO: list {{{
--    better quickfix list navigation, preview, jumping (workflow)
--      https://www.youtube.com/watch?v=AuXZA-xCv04
--      update quickfix list on changes (e.g. delete TODO)
--      difference between quickfix and location lists
--      enable list wrap in quickfix window
--    transparent background
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
vim.keymap.set( "n", "]q", ":cnext<cr>zv", {})
vim.keymap.set( "n", "[q", ":cprev<cr>zv", {})
vim.keymap.set("n", "zh", "zM zv", { desc = "fold everywhere but here" })

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
-- WSL2/tmux terminal background detection fix
if vim.fn.has("wsl") == 1 then
  -- Query Windows registry for current theme (light=1, dark=0)
  local is_dark = vim.fn.system("powershell.exe -NoProfile -Command '[int](Get-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize\" -Name AppsUseLightTheme).AppsUseLightTheme'"):match("0")
  vim.o.background = is_dark == "0" and "dark" or "light"
end
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

-- Utilities (lightweight plugins) {{{
--
-- grep todo keywords and add to quickfix
if vim.fn.executable('rg') then
  vim.opt.grepprg = "rg --vimgrep --no-hidden --no-heading"
end
vim.api.nvim_create_user_command("Todos", function()
 vim.cmd.vimgrep({ '/\\(TODO\\|FIXME\\|IDEA\\|TRACK\\):/', '**/*' })
 vim.cmd.copen()
end, { desc = "vimgrep TODO: and friends to quickfix", nargs = 0 })

-- highlight todo keywords
vim.api.nvim_set_hl(0, "darkTodoPattern", { fg = "#ffaf00", bold = true })
vim.api.nvim_set_hl(0, "lightTodoPattern", { fg = "#cd4848", bold = true })
vim.api.nvim_create_autocmd({ "ColorScheme", "OptionSet", "VimEnter" }, {
  callback = function()
    vim.fn.clearmatches()
    if vim.o.background == "dark" then
      vim.fn.matchadd("darkTodoPattern", "\\(TODO\\|FIXME\\|IDEA\\|TRACK\\):")
    else
      vim.fn.matchadd("lightTodoPattern", "\\(TODO\\|FIXME\\|IDEA\\|TRACK\\):")
    end
  end
})
-- }}}

-- Filetype specifics {{{
-- This autocmd is to fix the problem of '--' indentation being right-shifted by
-- two spaces only after lines with foldmarkers like '\{\{\{'
-- these stay here; timing is wrong if these are moved to 'after/ftplugin/lua.lua'
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.indentexpr = "v:lua.lua_indent(v:lnum)"
  end,
})
-- This autocmd defines the function to fix the '--' indentation problem
-- addressed by the previous autocmd
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    _G.lua_indent = function(lnum)
      local line = vim.fn.getline(lnum)
      if line:match("^%s*--%s*") then  -- On comment lines/spaces after --, match prev comment indent
        local prev = vim.fn.prevnonblank(lnum - 1)
        if prev > 0 then
          return vim.fn.indent(prev)
        end
      end
      return vim.fn.eval("GetLuaIndent(" .. lnum .. ")")  -- Fallback to Lua indent
    end
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "init.lua",
  callback = function()
    vim.opt.foldmethod = "marker"
    vim.opt.foldmarker = "{{{,}}}"
    vim.opt.foldlevel = 0
  end,
})
-- }}}

-- big markdown ideas list {{{
-- list of suggestions
--  https://mambusskruj.github.io/posts/pub-neovim-for-markdown/#syntax-highlights-and-conceals
--
--    - https://github.com/iwe-org/iwe
--    - https://github.com/jakewvincent/mkdnflow.nvim
--    - previewing:
--      - synced external preview
--    - table of contents: markdown-toc, https://youtu.be/BVyrXsZ_ViA
--    - url linking improvements
--      - fast entry
--        - paste from clipboard with prompt for link title
--          - or else a snippet
--        - paste from clipboard in visual mode
--        - shortcut to title the url under the cursor
--      - use TOC to jump/navigate
--    - filetype changes
--      - textwidth (e.g. 100, 120?)
--        - can this be set within specific files, e.g. for prose vs. notes differences?
--    - table input and manipulation
--    - image support
--    - A couple of videos to start ideas:
--      - <https://www.youtube.com/watch?v=DgKI4hZ4EEI>
--      - <https://linkarzu.com/posts/neovim/markdown-setup-2025/>
--    - other ideas:
--      - easier bolding etc. with mini.surround and/or keymaps
--      - better bullet lists: https://github.com/bullets-vim/bullets.vim
-- }}}

-- Archived info {{{
--  Improving vimgrep+quickfix workflow
--    https://gist.github.com/romainl/56f0c28ef953ffc157f36cc495947ab3
--  TRACK: g-<c-g> to output word/line count in visual mode
--    not an issue with 0.11.4. --clean -u NORC doesn't help
--    WAR: use :messages to get the text from g-<c-g>
--
--  TRACK: To fix folded code blocks in markdown files completely disappearing,
--  we need to disable the 'conceal_lines' on the fenced_code_block delimiters.
--  According to
--  https://www.reddit.com/r/neovim/comments/1jo6d1n/how_do_i_override_treesitter_conceal_lines/
--  we really only have 2 options at the moment:
--  1. copy share/nvim/runtime/queries/markdown/highlights.scm to
--  .config/nvim/queries/markdown and remove those lines (and without ';; extends')
--  2. remove the lines directly from the runtime highlights.scm file itself
-- }}}
