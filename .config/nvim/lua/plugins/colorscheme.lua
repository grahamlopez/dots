return {
	{
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 900,
    config = function()
    	vim.cmd.colorscheme("default")
    end,
	},
	{
    -- neovim detects terminal background at startup, BUT
    -- doesn't work inside tmux
    -- doesn't affect already-running instances
    -- not needed anymore? https://github.com/vimpostor/vim-lumen?tab=readme-ov-file#is-this-plugin-still-needed-with-latest-vim
    -- this works, but TMUX doesn't propogate the DEC 2031 escape sequence to
    -- applications running inside of it
    -- but looks like there is a merged PR: https://github.com/tmux/tmux/pull/4353
    { "f-person/auto-dark-mode.nvim", opts = {} }, -- https://github.com/f-person/auto-dark-mode.nvim
	},
}
