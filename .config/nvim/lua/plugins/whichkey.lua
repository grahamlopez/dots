-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/whichkey.lua
--[[
    to query a current mapping use `:map <leader>h` and its mode variants
    `:map` by itself will show all user-defined mappings
    to ask about a key that starts with control, type `C-v` first, then the key sequence

    see a default mapping, use `:help` followed by the keysequence, or e.g. CTRL-P

    for modes, see `:help map-modes`
--]]
return {
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

  end
}


