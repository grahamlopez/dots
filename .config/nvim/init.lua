-- to reload the config and clear the lua module cache
-- because ':source $MYVIMRC' only reloads init.lua, but leaves all the
-- 'require'd lua modules cached
local function reload_config()
  for name, _ in pairs(package.loaded) do
    if name:match("^user") then -- we can filter what we remove
      package.loaded[name] = nil
    end
  end
  dofile('/home/graham/.config/grahamvim/init.lua')
end
vim.api.nvim_create_user_command('ReloadConfig', reload_config, { desc = 'Reload Neovim configuration' })

-- Set <space> as the leader key
-- See `:help mapleader`
-- Ensure this happens before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("user.launch")
require("user.options")
require("user.keymaps")
-- require("user.autocmds")
spec("user.colorscheme")
spec("user.devicons")
spec("user.treesitter")
spec("user.mason")
-- spec("user.cmp")
spec("user.lspconfig")
spec("user.telescope")
-- spec("user.none-ls")
-- spec("user.illuminate")
-- spec("user.gitsigns")
-- spec("user.comment")
spec("user.lualine")
-- spec("user.navic")
-- spec("user.breadcrumbs")
-- spec("user.harpoon")
-- spec("user.neotest")
-- spec("user.nvimtree")
-- spec("user.autopairs")
-- spec("user.neogit")
-- spec("user.alpha")
-- spec("user.project")
-- spec("user.indentline")
-- spec("user.toggleterm")
spec("user.aerial")
spec("user.highlightedyank")
spec("user.whichkey")
require("user.lazy")


vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = function()
    -- set this to match line numbering?
    -- FIXME adapt to dark/light theme
    vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#121212" })
  end
})

-- bookmarked: https://www.youtube.com/live/KGJV0n70Mxs?si=wTR54z6DlkwDDa90&t=6843

--[[
    Resources:
    chris@machine "Ultimate Neovim Config | 2024 | Launch.vim" YT vid: https://www.youtube.com/watch?v=KGJV0n70Mxs
    Vhyrro on YT "Understanding Neovim" playlist: https://www.youtube.com/playlist?list=PLx2ksyallYzW4WNYHD9xOFrPRYGlntAft
    Typecraft "Neovim for Newbs" YT playlist: https://www.youtube.com/playlist?list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn
    The Rad Lectures "How to setup Neovim from Scratch" YT vid: https://www.youtube.com/watch?v=ZjMzBd1Dqz8

    Usage hints, since I don't have a better place right now
    - to get error messages from language server, use 'gl'
      - then hit 'gl' again to focus the popup, and 'yy' to clipboard for pasting into google
      - alternatively, can enable inline virtual text in lspconfig.lua
    - to see contents of internal tables like 'vim.treesitter' and 'vim.lsp', use
      `:lua print(vim.lsp)` or a shortcut `:=vim.lsp`

    Working notes and plan
    1. Harvest YT videos above for plugin and configuration ideas
    2. Enable plugin set
    3. Configure keybinging set (check lazyvim etc. for ideas)
    4. Optimize startup time
    5. Read docs for plugins and further configuration
    6. Fixmes and todos

    Ideas for extending
    - use inline virtual text (ghost text) with completions:
      - https://www.reddit.com/r/neovim/comments/t1gm0e/how_can_i_get_an_inline_preview_for_the/
    - make LSP diagnostics only visible when cursor is on trouble line/spot
      - https://github.com/dgagn/diagflow.nvim
    - (done) enable undercurls to show where in the line the LSP diagnostic applies
      - https://www.reddit.com/r/neovim/comments/nc34j7/cannot_get_undercurls_to_display_for_lsp/
      - https://github.com/tmux/tmux/issues/3494
      - https://github.com/AstroNvim/AstroNvim/issues/1336
      - https://github.com/folke/lsp-colors.nvim#making-undercurls-work-properly-in-tmux
      - echo -e "\e[4:3mTEST"   to test the terminal
      - works in konsole, not in alacritty, not in tmux in either
      - okay, TERM=alacritty must be set when alacritty starts (e.g. from .zshrc), then undercurl
        works in nvim+tmux. needed to remove all other overrides in .tmux.conf. Interestingly,
        konsole doesn't seem to care that TERM=alacritty. but TODO let's clean up dotfiles for this
    - understand how numbered :registers work and getting yank history
    - update "open neovim config" keymap to also update the working directory and restore it when done
    - enable TODO and FIXME for all buffer types, telescope to find them and preview, send to quick/location list
    - improve fold navigation: h/l to close/open
    - repeatable motions - can '.' be used after e.g. 'f/F'
    - repeatable window sizing
    - working colorscheme previews with telescope
      - preview both light/dark modes for themes that support it (e.g. lunarpeche)
    - integration with clipboard, even from tmux

    Bugs to upstream
    - treesitter context to show multiple markdown headings like it does for lua code
      -- looks like a bug? the sections are properly nested under :InspectTree
    - aerial syncing with buffer

    Other plugins to be aware of
    -- schemastore -- lint/complete using schemas for json, yaml, toml
    -- file browsers: nvim-tree, oil, telescope-file-browser (stay away from neotree)
    -- close buffer but leave split open: https://github.com/qpkorr/vim-bufkill or https://github.com/ojroques/nvim-bufdel
    --  - can also approximate with keymappings like ":bp<cr>:bd #"
    --  dressing.nvim
    --  document/code outline+navigation: stevearc/aerial and hedyhli/outline
    --  https://github.com/onsails/lspkind.nvim for vscode-like pictograms for lsp

    For writing mode
    -- https://trebaud.github.io/posts/neovim-for-writers/
    -- https://miragiancycle.github.io/OVIWrite/
    -- https://bhupesh.me/writing-like-a-pro-with-vale-and-neovim/
    -- https://www.reddit.com/r/neovim/comments/z26vhz/how_could_i_use_neovim_for_general_writing_and/
    -- can a proportional font be used?
--]]
