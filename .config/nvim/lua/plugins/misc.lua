return {
  {
    -- Session management. This saves your session in the background,
    -- keeping track of open buffers, window arrangement, and more.
    -- You can restore sessions when returning through the dashboard.
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      branch = false,
      need = 2,
    },
    config = function() -- part of what's needed to preserve bufferline ordering
      require("persistence").setup({
        options = { "globals" }, -- include other options as needed
        pre_save = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
        end,
      })
    end,
    -- stylua: ignore
  },
  {
    -- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/whichkey.lua
    --[[
        to query a current mapping use `:map <leader>h` and its mode variants
        `:map` by itself will show all user-defined mappings
        to ask about a key that starts with control, type `C-v` first, then the key sequence

        see a default mapping, use `:help` followed by the keysequence, or e.g. CTRL-P

        for modes, see `:help map-modes`
    --]]
    "folke/which-key.nvim", -- https://github.com/folke/which-key.nvim
    config = function()
      require("which-key").setup({
        --preset = "helix",
        --win = {
        --  width = { min = 30, max = 60 },
        --  height = { min = 4, max = 0.75 },
        --  padding = { 0, 1 },
        --  col = 1,
        --  row = -1,
        --  border = "rounded",
        --  title = true,
        --  title_pos = "left",
        --},
        --layout = {
        --  width = { min = 30 },
        --},
        --preset = "modern"
        win = {
          width = 0.9,
          height = { min = 4, max = 25 },
          col = 0.5,
          row = -5,
          border = "rounded",
          padding = { 1, 3 },
          title = true,
          title_pos = "center",
          wo = { winblend = 15 },
        },
        icons = {
          mappings = false,
        },
      })
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    specs = { -- not sure if this part should go in the snacks picker config
      {
        "folke/snacks.nvim",
        opts = {
          picker = {
            win = {
              input = {
                keys = {
                  ["<a-s>"] = { "flash", mode = { "n", "i" } },
                  ["s"] = { "flash" },
                },
              },
            },
            actions = {
              flash = function(picker)
                require("flash").jump({
                  pattern = "^",
                  label = { after = { 0, 0 } },
                  search = {
                    mode = "search",
                    exclude = {
                      function(win)
                        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                      end,
                    },
                  },
                  action = function(match)
                    local idx = picker.list:row2idx(match.pos[1])
                    picker.list:_move(idx, true, true)
                  end,
                })
              end,
            },
          },
        },
      },
    },
  },
}
