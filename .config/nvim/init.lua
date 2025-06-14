-- to reload the config and clear the lua module cache
-- because ':source $MYVIMRC' only reloads init.lua, but leaves all the
-- 'require'd lua modules cached
local function reload_config()
  for name, _ in pairs(package.loaded) do
    if name:match("^user") then -- we can filter what we remove
      package.loaded[name] = nil
    end
  end
  dofile("/home/graham/.config/nvim/init.lua")
end
vim.api.nvim_create_user_command("ReloadConfig", reload_config, { desc = "Reload Neovim configuration" })

-- Set <space> as the leader key
-- See `:help mapleader`
-- Ensure this happens before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- https://github.com/folke/lazy.nvim
--[[
    get lazy if it isn't already there
    .e.g try `:lua print(vim.fn.stdpath("data"))`
    and even `:lua print(vim.fn.stdpath "data" .. "/lazy/lazy.nvim")
--]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
-- now prepend it to the runtime path
vim.opt.rtp:prepend(lazypath)

--[[
    configure the lazy plugin manager itself. see
    https://lazy.folke.io/configuration
--]]
require("lazy").setup({
  import = "plugins", -- use 'enabled = false' if needed
  ui = {
    border = "rounded",
  },
  change_detection = {
    enabled = false,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        "netrw",
        "netrwPlugin",
        -- "tarPlugin",
        "tohtml",
        "tutor",
        -- "zipPlugin",
      },
    },
  },
})

-- workaround for nvim 0.10.3 when using :Inspect
vim.hl = vim.highlight

-- These could also go in 'plugin/' like teejdv.
-- Not sure about which of these options is best for ordering, etc.
require("settings.options")
require("settings.autocmds")
require("settings.keymaps")

--[[
    Summer 2025:
    I think LazyVim has evolved to be pretty close to what I want, but I still want to
    build it up from scratch. So I'm drawing a lot of hints and inspiration from there.

    a neat book to double-check understanding: https://lazyvim-ambitious-devs.phillips.codes/course/chapter-1/

    As I go along trying to set up the various pieces of snacks.nvim, I keep hitting little
    annoying problems. I guess I might be going back to "completely from scratch" even if
    I use LazyVim as a demonstration of what should be possible.

    snacks problems:
    - todo-comments.nvim and snacks.picker.todo_comments()
    - snacks.toggle
    - snacks.indent
    - generally poor documentation
    - seemingly incomplete functionality made up for in other places in LazyVim (could be skill issue)

    It might be time to plan something top-down, as this seems to become very piecemeal
    and fragile

    A new picture. Just because a plugin is present doesn't mean it is required. Current plugins are
    shown here to help understand context and organization.

    lua/
      after/
        ftplugin/
          lua.lula
      plugins/
        ai.lua
          (code agent)
        appearance.lua
          (theming)
            transparent.nvim
            auto-dark-mode.nvim
          (ui elements appearance)
            nvim-lualine/lualine.nvim
              nvim-tree/nvim-web-devicons
            akinsho/bufferline.nvim
          (zen/focus modes)
          (outline)
        coding.lua
          (code formatting)
            conform.nvim
          (git)
            gitsigns.nvim
          (lsp)
            neovim/nvim-lspconfig
              williamboman/mason.nvim
              willialmboman/mason-lspconfig.nvim
              WhoIsSethDaniel/mason-tool-installer.nvim
              folke/lazydev.nvim
              j-hui/fidget.nvim
          (fixme/todo)
          (debugging)
        ui.lua
          (movement)
            folke/flash.nvim
          (pickers)
            folke/snacks.nvim (picker)
            nvim-telescope/telescope.nvim
          (keybinding)
            folke/which-key.nvim
          (completion)
          (file explorer)
          (tab pages, zoom window)
        utility.lua
          (syntax)
            nvim-treesitter/nvim-treesitter
            nvim-treesitter/nvim-treesitter-context
          (session)
            folke/persistence.nvim
          (clipboards/registers)
          (spell)
          (folding)
      settings/
        autocmds.lua
        keymaps.lua
        options.lua

    TODO:
    - [ ] zoom window / tab workflow
        - for "zooming" windows (:tab split)
        - for isolating cwd
        - how to minimize cognitive load
          - visual cues (lualine config)
          - keybindings
    - [ ] understand clipboards
        - between separate nvim processes
        - interaction with system clipboard
        - can an nvim open shortcut + picker replace something like clipse?
    - [ ] git workflows
    - [ ] fixme/todo, etc. handling (folke/todo-comments.nvim)
    - [ ] enable mouse for bufferline (select and close)
    - [ ] consistent and predictable 'gq' line-wrapping behavior
        - currently a problem especially in markdown files and lua comments
    - [ ] integrated AI: first task is to help me with my nvim configs
    - [ ] read through and understand spell checking settings, files, workflows

    WSL:
    - [ ] whichkey window shows text from underneath and is generally garbled

    Configuration examples:

    https://github.com/tjdevries/config.nvim
    https://github.com/nvim-lua/kickstart.nvim
    https://github.com/LunarVim/Launch.nvim

    Resources:

    TJ DeVries
    - personal config rewrite 2024: https://www.youtube.com/watch?v=kJVqxFnhIuw&t=5s
      - full stream at https://www.youtube.com/@teej_daily/videos
      - how lazy works for loading plugins
      - how to structure plugin configuration for fast iteration
      - after/ftplugins for language-specific options and mappings

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

    Todo
    - neovim config hacking: shortcuts to get to it, dots repo aware
    - markdown
    - folding
    - git
    - projects
    - completion

    Configuration fixes
    - how to see all mappings for any given situation (which-key display, when using telescope, when
      on the command prompt, etc.)
    - Telescope man_pages only displays section 1 manuals
    - treesitter-based folding that includes lua comment blocks
    - 'gq' in visual mode doesn't work for lua comments, but when typing past col 80 for
      single line comments, it automatically breaks and adds the '--' (as if 'gq' should work)

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

    How to conditionally enable/disable plugins using an environment variable at neovim start
    https://youtu.be/M0B_24d0MWw?si=dEKMd606Gg6oC82A&t=376

    Other plugins to be aware of
    -- hedyhil/outline.nvim and stevearc/aerial.nvim for outline navigation
    -- https://github.com/ThePrimeagen/harpoon/tree/harpoon2 for arbitrary shortcuts
    -- fzf-lua as alternative to telescope (picker); faster for large directories
    -- mini files for a filesystem browser
    -- hardtime.nvim for breaking bad habits
    -- REST client: https://github.com/mistweaverco/kulala.nvim
    -- schemastore -- lint/complete using schemas for json, yaml, toml
    -- file browsers: nvim-tree, oil, telescope-file-browser (stay away from neotree)
    -- close buffer but leave split open:
    --  https://github.com/qpkorr/vim-bufkill or https://github.com/ojroques/nvim-bufdel
    --  - can also approximate with keymappings like ":bp<cr>:bd #"
    -- dressing.nvim
    -- document/code outline+navigation: stevearc/aerial and hedyhli/outline
    -- https://github.com/onsails/lspkind.nvim for vscode-like pictograms for lsp
    --
    --  https://dotfyle.com/neovim/plugins/trending
    --  https://neovimcraft.com/
    --  neopopes as identified by Justin Keyes
    --    https://github.com/echasnovski
    --    https://github.com/folke
    --    https://github.com/mfussenegger
    --    https://github.com/nvchad

    AI/LLM tools
    -- https://neovim.discourse.group/t/what-is-the-current-and-future-state-of-ai-integration-in-neovim/5303
    -- https://github.com/olimorris/codecompanion.nvim
    -- https://www.reddit.com/r/neovim/comments/1krv35v/announcing_sllmnvim_chat_with_llms_directly_in/
    -- https://github.com/yetone/avante.nvim

    For writing mode
    -- https://trebaud.github.io/posts/neovim-for-writers/
    -- https://miragiancycle.github.io/OVIWrite/
    -- https://bhupesh.me/writing-like-a-pro-with-vale-and-neovim/
    -- https://www.reddit.com/r/neovim/comments/z26vhz/how_could_i_use_neovim_for_general_writing_and/
    -- can a proportional font be used?
    -- I started a config at .config/nvim.writin - see hash 2c5f0eb for latest

    Previously discovered plugins that were in git - mostly only partially configured/explored
    See hash 2c5f0eb in dotfiles repo for latest state before removal
    -- alpha, autopairs, breadcrumbs, comment, gitsigns, harpoon, icons,
    -- illuminate, indentline, launch, lazy, navic, neogit, neotest, none-ls,
    -- nvimtree, project, toggleterm, aerial, devicons, highlightedyank,
    -- lspconfig, mason, whichkey
--]]
