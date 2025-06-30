
a neat book to double-check some understanding: <https://lazyvim-ambitious-devs.phillips.codes/course/chapter-1/>

Configuration examples:

<https://github.com/tjdevries/config.nvim>
<https://github.com/nvim-lua/kickstart.nvim>
<https://github.com/LunarVim/Launch.nvim>

Resources:

TJ DeVries

- personal config rewrite 2024: <https://www.youtube.com/watch?v=kJVqxFnhIuw&t=5s>
  - full stream at <https://www.youtube.com/@teej_daily/videos>
  - how lazy works for loading plugins
  - how to structure plugin configuration for fast iteration
  - after/ftplugins for language-specific options and mappings

chris@machine "Ultimate Neovim Config | 2024 | Launch.vim" YT vid: <https://www.youtube.com/watch?v=KGJV0n70Mxs>
Vhyrro on YT "Understanding Neovim" playlist: <https://www.youtube.com/playlist?list=PLx2ksyallYzW4WNYHD9xOFrPRYGlntAft>
Typecraft "Neovim for Newbs" YT playlist: <https://www.youtube.com/playlist?list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn>
The Rad Lectures "How to setup Neovim from Scratch" YT vid: <https://www.youtube.com/watch?v=ZjMzBd1Dqz8>

Ideas for extending

- use inline virtual text (ghost text) with completions:
  - <https://www.reddit.com/r/neovim/comments/t1gm0e/how_can_i_get_an_inline_preview_for_the/>
- make LSP diagnostics only visible when cursor is on trouble line/spot
  - <https://github.com/dgagn/diagflow.nvim>
- (done) enable undercurls to show where in the line the LSP diagnostic applies
  - <https://www.reddit.com/r/neovim/comments/nc34j7/cannot_get_undercurls_to_display_for_lsp/>
  - <https://github.com/tmux/tmux/issues/3494>
  - <https://github.com/AstroNvim/AstroNvim/issues/1336>
  - <https://github.com/folke/lsp-colors.nvim#making-undercurls-work-properly-in-tmux>
  - echo -e "\e[4:3mTEST" to test the terminal
  - works in konsole, not in alacritty, not in tmux in either
  - okay, TERM=alacritty must be set when alacritty starts (e.g. from .zshrc), then undercurl
    works in nvim+tmux. needed to remove all other overrides in .tmux.conf. Interestingly,
    konsole doesn't seem to care that TERM=alacritty. but TODO let's clean up dotfiles for this
- repeatable motions - can '.' be used after e.g. 'f/F'
- repeatable window sizing

Bugs to upstream

- treesitter context to show multiple markdown headings like it does for lua code
  -- looks like a bug? the sections are properly nested under :InspectTree
- aerial syncing with buffer

How to conditionally enable/disable plugins using an environment variable at neovim start
<https://youtu.be/M0B_24d0MWw?si=dEKMd606Gg6oC82A&t=376>

Other plugins to be aware of
-- <https://github.com/ThePrimeagen/harpoon/tree/harpoon2> for arbitrary shortcuts
-- hardtime.nvim for breaking bad habits
-- REST client: <https://github.com/mistweaverco/kulala.nvim>
-- file browsers: nvim-tree, oil, telescope-file-browser (stay away from neotree)
-- dressing.nvim
-- <https://github.com/onsails/lspkind.nvim> for vscode-like pictograms for lsp
--

-- <https://dotfyle.com/neovim/plugins/trending>
-- <https://neovimcraft.com/>
-- neopopes as identified by Justin Keyes
-- <https://github.com/echasnovski>
-- <https://github.com/folke>
-- <https://github.com/mfussenegger>
-- <https://github.com/nvchad>

AI/LLM tools
-- <https://neovim.discourse.group/t/what-is-the-current-and-future-state-of-ai-integration-in-neovim/5303>
-- <https://github.com/olimorris/codecompanion.nvim>
-- <https://www.reddit.com/r/neovim/comments/1krv35v/announcing_sllmnvim_chat_with_llms_directly_in/>
-- <https://github.com/yetone/avante.nvim>

For writing mode
-- <https://trebaud.github.io/posts/neovim-for-writers/>
-- <https://miragiancycle.github.io/OVIWrite/>
-- <https://bhupesh.me/writing-like-a-pro-with-vale-and-neovim/>
-- <https://www.reddit.com/r/neovim/comments/z26vhz/how_could_i_use_neovim_for_general_writing_and/>
-- focus/zen modes
-- comments, sidebar, etc.
-- can a proportional font be used?
-- I started a config at .config/nvim.writing - see hash 2c5f0eb for latest

PKM / logseq reproduction
-- linking, backlinking, tagging
-- how much of logseq to bring forward?
-- more mouse support

Previously discovered plugins that were in git - mostly only partially configured/explored
See hash 2c5f0eb in dotfiles repo for latest state before removal
-- alpha, autopairs, breadcrumbs, comment, harpoon, icons,
-- illuminate, indentline, launch, navic, neogit, neotest, none-ls,
-- nvimtree, project, toggleterm, devicons, highlightedyank,
