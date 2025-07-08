-- seems like a bit of a hammer instead of figuring out why/where these
-- are being changed
-- It might only happen when opening multiple files at once; this also happens
-- for other filetypes as well. Workarounds:
--  - put options into these kinds of after/ftplugin files
--  - put options in a global FileType autocommand with pattern = *
--  - use `:e another_file`, `:argadd *` to avoid opening multiple files on cli
--  - a session restore like persistence.nvim to avoid opening multiple files
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

--[[ IDEA: big markdown ideas list
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
