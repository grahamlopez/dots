-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/autocmds.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = function()
    -- set this to match line numbering?
    -- FIXME adapt to dark/light theme
    vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#121212" })
    vim.api.nvim_set_hl(0, "MatchParen", { ctermbg = "yellow", bg = "yellow" })
    vim.api.nvim_set_hl(0, "NormalFloat", { ctermbg = "NONE", bg = "NONE" })
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

-- Neovim 0.11 built-in LSP enhancements
-- Enable native completion when LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    -- Enable auto-completion
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    -- Auto-format on save for supported servers
    -- TODO understand the differences between this and conform()'s formatting which to set, etc.
    if
        not client:supports_method("textDocument/willSaveWaitUntil")
        and client:supports_method("textDocument/formatting")
    then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("lsp-format", { clear = false }),
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end
  end,
})
