-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
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

-- General settings
vim.opt.mouse = "nv" -- Disable mouse for speed
vim.opt.clipboard = "unnamed,unnamedplus" -- Enable '*' and '+'; need wl-clipboard
vim.opt.undofile = true -- Persistent undo
-- vim.opt.backup = false -- No backup files
-- vim.opt.writebackup = false -- No backup before overwriting
-- vim.opt.swapfile = false -- No swap files
vim.opt.updatetime = 250 -- Faster completion (4000ms default)
vim.opt.timeoutlen = 300 -- Faster which-key popup
vim.opt.history = 1000 -- More command history
vim.opt.virtualedit = "block"

-- Performance optimizations
vim.opt.lazyredraw = true -- Don't redraw during macros
-- opt.regexpengine = 1 -- Use old regex engine (faster for some patterns)
vim.opt.ttyfast = true -- Fast terminal connection

-- Search settings
vim.opt.hlsearch = true -- Set highlight on search
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
vim.opt.inccommand = "split"
vim.opt.shortmess:append("c")

-- Appearance
vim.opt.termguicolors = true -- make sure your terminal supports this (most do)
vim.opt.number = true -- Make line numbers default
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
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
vim.opt.showtabline = 2

-- Indentation and formatting
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

-- Splitting
vim.opt.splitbelow = true -- Horizontal splits go below
vim.opt.splitright = true -- Vertical splits go right

-- Completion
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
vim.opt.pumheight = 10 -- Popup menu height
vim.opt.wildmode = "longest:full,full" -- Command completion mode
vim.opt.wildignore:append({ "*.o", "*.obj", ".git", "node_modules", "*.pyc" })

-- Folding (enhanced for Neovim 0.11)
-- TODO: Folding: closed fold display, easier display of collapsed + 1
-- better navigation, h/l to open/close, lua block comments, what can be done
-- about fold debugging e.g. showing fold locations, etc.?
vim.opt.foldmethod = "expr" -- Use expression folding
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- TreeSitter folding
vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()" -- TreeSitter fold text with syntax highlighting
vim.opt.foldlevel = 99 -- Open all folds by default
vim.opt.foldlevelstart = 99 -- Start with all folds open
vim.opt.foldenable = true -- Enable folding
vim.opt.foldcolumn = "0" -- No fold column (clean appearance)
vim.opt.foldtext = ""
vim.opt.fillchars="fold: "

-- Spell checking (disabled by default, easily toggled)
vim.opt.spell = false
vim.opt.spelllang = { "en_us" }
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

-- Session options
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

-- Better diffs
vim.opt.diffopt:append("linematch:60")

-- Neovim 0.11 specific optimizations
if vim.fn.has("nvim-0.11") == 1 then
  -- Use new list_extend behavior
  vim.opt.listchars = {
    tab = "→ ",
    trail = "·",
    nbsp = "○",
    extends = "▸",
    precedes = "◂",
  }

  -- Enhanced diagnostic settings
  vim.opt.signcolumn = "yes:1" -- Fixed width sign column
end

-- File handling
vim.opt.hidden = true -- Allow hidden buffers
vim.opt.autoread = true -- Auto-read changed files
vim.opt.autowrite = true -- Auto-write before running commands

-- Disable some providers for faster startup
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python_provider = 0
-- Keep Python3 provider for some plugins that need it
-- vim.g.loaded_python3_provider = 0

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

-- Point to host-specific stuff for local development environments
if vim.uv.os_gethostname() == 'fi-kermit' then
  if vim.fn.isdirectory(vim.fn.expand('~/local/deps/neovim-venv')) ~= 0 then
    vim.g.python3_host_prog = vim.fn.expand('~/local/deps/neovim-venv/bin/python')
  end
end


-- Key improvements:
--
-- 1. **Performance**: Disabled swap files, faster timeouts, lazy redraw
-- 2. **Neovim 0.11 Folding**: Uses native TreeSitter folding with syntax highlighting
-- 3. **Better Diagnostics**: Enhanced sign column and completion settings
-- 4. **WSL Support**: Better clipboard integration for WSL users
-- 5. **Minimal UI**: Clean appearance with essential information only

--[[
    these are taken from
    https://www.youtube.com/watch?v=KGJV0n70Mxs
    deduped with mine above
--]]
-- vim.opt.backup = false -- creates a backup file
-- vim.opt.cmdheight = 1 -- more space in the neovim command line for displaying messages
-- vim.opt.conceallevel = 0 -- so that `` is visible in markdown files
-- -- vim.opt.fileencoding = "utf-8" -- the encoding written to a file
-- vim.opt.pumheight = 10 -- pop-up menu height
-- vim.opt.pumblend = 10 -- transparency-ish for pop-up menu
-- vim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
-- vim.opt.swapfile = false -- creates a swapfile
-- vim.opt.undofile = true -- enable persistent undo
-- vim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
-- vim.opt.laststatus = 3
-- vim.opt.showcmd = false
-- vim.opt.ruler = false
-- vim.opt.numberwidth = 4 -- set number column width to 2 {default 4}
-- vim.opt.signcolumn = "yes" -- always show the sign column, otherwise it would shift the text each time
-- vim.opt.wrap = false -- display lines as one long line
-- vim.opt.scrolloff = 0
-- vim.opt.sidescrolloff = 8
-- vim.opt.guifont = "monospace:h17" -- the font used in graphical neovim applications
-- vim.opt.title = false
-- -- colorcolumn = "80",
-- -- colorcolumn = "120",
-- vim.opt.fillchars = vim.opt.fillchars + "eob: "
-- vim.opt.fillchars:append {
--   stl = " ",
-- }
--
-- vim.opt.shortmess:append "c"
--
-- vim.cmd "set whichwrap+=<,>,[,],h,l"
--
-- vim.g.netrw_banner = 0
-- vim.g.netrw_mouse = 2
