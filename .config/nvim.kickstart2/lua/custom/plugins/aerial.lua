return {
  'stevearc/aerial.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },

  config = function()
    require('aerial').setup {
      -- optionally use on_attach to set keymaps when aerial has attached to a buffer
      on_attach = function(bufnr)
        -- Jump forwards/backwards with '{' and '}'
        -- vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
        -- vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
      end,
      -- manage_folds = true,
      -- link_folds_to_tree = true,
      -- link_tree_to_folds = true,
      backends = {
        markdown = { 'markdown' },
        ['_'] = { 'treesitter', 'lsp', 'markdown', 'man' },
      },
      open_automatic = false,
      show_guides = true,
    }
  end,
}
