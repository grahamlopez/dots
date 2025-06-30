-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/autocmds.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = function()
    -- stylua: ignore start
    vim.cmd('highlight Folded guibg=NONE')
    if vim.o.background == "dark" then
      vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 233, bg = "#121212" })
      vim.api.nvim_set_hl(0, "MatchParen", { ctermbg = "yellow", bg = "yellow" })
    else
      vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 255, bg = "#EEEEEE" })
      vim.api.nvim_set_hl(0, "MatchParen", { ctermbg = "yellow", bg = "yellow" })
    end
    -- stylua: ignore end
  end,
})

-- Set environment variables for git when working on nvim config
local home = os.getenv("HOME")
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
  callback = function()
    if vim.fn.getcwd() == home .. "/.config/nvim" then
      vim.env.GIT_DIR = home .. "/.dots-git/"
      vim.env.GIT_WORK_TREE = home
    end
  end,
})

-- open help windows in vertical split depending on window size
local function move_help_window()
  if vim.api.nvim_win_get_width(0) > 160 then
    vim.cmd.wincmd("L")
  else
    vim.cmd.wincmd("J")
    vim.cmd("resize " .. math.floor(vim.o.lines * 0.65))
  end
end

-- BUG: having both of these autocmds causes a .35 bottom blank space under
-- the status line on WSL; the resize command gets called after the vertical
-- split happens

-- this one is needed to catch the first time a certain help page is opened
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = move_help_window,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    if vim.bo.filetype == "help" then
      move_help_window()
    end
  end,
})

-- Neovim 0.11 built-in LSP enhancements
-- Enable native completion when LSP attaches
-- disabled for blin.nvim and conform.nvim, respectively
-- vim.api.nvim_create_autocmd("LspAttach", {
--   group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
--   callback = function(args)
--     local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
--
--     -- Enable auto-completion
--     if client:supports_method("textDocument/completion") then
--       vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
--     end
--
--     -- Auto-format on save for supported servers
--     if
--         not client:supports_method("textDocument/willSaveWaitUntil")
--         and client:supports_method("textDocument/formatting")
--     then
--       vim.api.nvim_create_autocmd("BufWritePre", {
--         group = vim.api.nvim_create_augroup("lsp-format", { clear = false }),
--         buffer = args.buf,
--         callback = function()
--           vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
--         end,
--       })
--     end
--   end,
-- })
