-- Global settings in init.lua (like vim.opt.tabstop = 2) get overridden by
-- filetype-specific indent scripts that load after your config during filetype
-- detection.
-- 
-- Neovim loads configs in this order:
--     init.lua (your global options)
--     Filetype detection (:help filetype)
--     runtime/indent/markdown.vim (sets tabstop=4, smartindent, etc. for markdown)
--     BufReadPost autocmd (but runs too early, before indent script)
-- 
-- The indent script ignores your globals and enforces its own values. Solution:
-- Use after/ftplugin/markdown.lua as recommended—it loads last via
-- runtimepath's after/ directory, overriding everything buffer-locally. See
-- :help ftplugin-override, :help runtimepath, :help after-directory.
-- 
-- Verify ordering with
-- :scriptnames          " Shows load sequence
-- :verbose set tabstop? " Reveals *where* option was last set (file:line)
--
vim.opt.tabstop = 2        -- Tab width
vim.opt.shiftwidth = 2     -- Indent width
vim.opt.softtabstop = 2    -- Soft tab width
vim.opt.expandtab = true   -- Use spaces instead of tabs
vim.opt.smartindent = true -- Smart autoindenting
vim.opt.autoindent = true  -- Copy indent from current line
vim.opt.breakindent = true -- Maintain indent when wrapping
vim.opt.wrap = false       -- Don't wrap lines
vim.opt.linebreak = true   -- Break at word boundaries if wrap enabled
vim.opt.textwidth = 80     -- Text width for formatting
vim.opt.foldlevel = 1
vim.opt.conceallevel = 2
-- vim.opt.concealcursor = "nc"
vim.treesitter.start(vim.api.nvim_get_current_buf(), "markdown") -- Force reload TS parser
-- To fix folded code blocks completely disappearing, we need to disable the
-- 'conceal_lines' on the fenced_code_block delimiters. According to
-- https://www.reddit.com/r/neovim/comments/1jo6d1n/how_do_i_override_treesitter_conceal_lines/
-- we really only have 2 options at the moment:
-- 1. copy share/nvim/runtime/queries/markdown/highlights.scm to
-- .config/nvim/queries/markdown and remove those lines (and without ';; extends')
-- 2. remove the lines directly from the runtime highlights.scm file itself

