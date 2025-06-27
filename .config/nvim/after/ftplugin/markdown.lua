-- HACK: seems like a bit of a hammer instead of figuring out why/where these
-- are being changed
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

--[[ TODO: markdown
    - linking workflow
      - fast entry
      - fast navigation
      - conceal display
    - filetype changes
      - textwidth (e.g. 100, 120?)
        - can this be set within specific files, e.g. for prose vs. notes differences?
    - visuals like linkarzu
    - (markdown is lingua-franca; no need yet to swim upstream on this one)
    - in-nvim rendering, synced preview
    - outline, folding, navigation
    - images
    - todo workflow
      - automatic and hidden timestamps
    - A couple of videos to start ideas:
      - <https://www.youtube.com/watch?v=DgKI4hZ4EEI>
      - <https://linkarzu.com/posts/neovim/markdown-setup-2025/>
--]]
