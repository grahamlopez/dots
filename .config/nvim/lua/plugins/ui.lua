-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/lualine.lua
-- https://github.com/nvim-lualine/lualine.nvim

return {
  {
    "nvim-lualine/lualine.nvim", -- https://github.com/nvim-lualine/lualine.nvim
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- https://github.com/nvim-tree/nvim-web-devicons
      lazy = true,
      event = "VeryLazy",
    },

    config = function()

      require('lualine').setup {
        options = {
          theme = 'nord',
          globalstatus = true,
        },
        sections = {
          lualine_c = { 'tabs' },
        },
      }

      require('nvim-web-devicons').setup { opts = {} }

    end
  },
  -- This is what powers LazyVim's fancy-looking
  -- tabs, which include filetype icons and close buttons.
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    -- keys = {
    --   { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    --   { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    --   { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    --   { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    --   { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    --   { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    --   { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    --   { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    --   { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    --   { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    -- },
    opts = {
      options = {
        -- stylua: ignore
    --    close_command = function(n) Snacks.bufdelete(n) end,
        -- stylua: ignore
    --    right_mouse_command = function(n) Snacks.bufdelete(n) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
    --    diagnostics_indicator = function(_, _, diag)
    --      local icons = LazyVim.config.icons.diagnostics
    --      local ret = (diag.error and icons.Error .. diag.error .. " " or "")
    --        .. (diag.warning and icons.Warn .. diag.warning or "")
    --      return vim.trim(ret)
    --    end,
    --    offsets = {
    --      {
    --        filetype = "neo-tree",
    --        text = "Neo-tree",
    --        highlight = "Directory",
    --        text_align = "left",
    --      },
    --      {
    --        filetype = "snacks_layout_box",
    --      },
    --    },
    --    ---@param opts bufferline.IconFetcherOpts
    --    get_element_icon = function(opts)
    --      return LazyVim.config.icons.ft[opts.filetype]
        numbers = "ordinal",
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}
