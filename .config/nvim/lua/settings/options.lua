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

    ':set all' to see all possible settings and their current values
    ':help options' to get to the options part of the manual
--]]

-- Tab / indentation
vim.opt.tabstop = 2      -- insert 2 spaces for a tab
vim.opt.shiftwidth = 2   -- the number of spaces inserted for each indentation
vim.opt.softtabstop = 2
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.smartindent = true
-- Search
vim.opt.hlsearch = true   -- Set highlight on search
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
-- Appearance
vim.opt.number = true        -- Make line numbers default
vim.opt.relativenumber = false
vim.opt.termguicolors = true -- NOTE: You should make sure your terminal supports this (most do)
vim.opt.signcolumn = 'yes'
vim.opt.colorcolumn = ''
vim.opt.scrolloff = 5
vim.opt.completeopt = { "menuone", "noselect", "noinsert" } -- For a better completion experience (mostly just for cmp)
vim.opt.breakindent = true                      -- Enable break indent
vim.opt.winheight = 5
vim.opt.winminheight = 5
vim.opt.winwidth = 5
vim.opt.winminwidth = 5
-- Behavior
vim.opt.undofile = true                         -- Save undo history
vim.opt.splitbelow = true
-- vim.cmd [[set iskeyword-=_]]
-- vim.opt.splitright = true
vim.opt.hidden = true
vim.opt.mouse = ''                              -- Disable mouse. Enable mouse mode with 'a'
vim.opt.clipboard = 'unnamedplus'               -- Sync clipboard between OS and Neovim.
vim.opt.textwidth = 80                          -- might want to enable this per filetype eventually not sure yet why 'gq' doesn't work well
vim.opt.updatetime = 250                        -- Decrease update time
vim.opt.timeoutlen = 500                        -- time to wait for a mapped sequence to complete
vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"
vim.opt.foldmethod = "expr" -- enable treesitter-based folding
--vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 9



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
-- vim.opt.showtabline = 1 -- always show tabs
-- vim.opt.smartindent = true -- make indenting smarter again
-- vim.opt.swapfile = false -- creates a swapfile
-- vim.opt.undofile = true -- enable persistent undo
-- vim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
-- vim.opt.cursorline = true -- highlight the current line
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
