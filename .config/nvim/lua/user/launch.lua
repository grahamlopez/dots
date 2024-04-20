-- https://github.com/LunarVim/Launch.nvim/blob/master/lua/user/launch.lua
--[[
    this whole scheme is a bit different than the normal way to set up
    lazy.nvim. The idea taken from this YT vid:
    https://www.youtube.com/watch?v=KGJV0n70Mxs

    This is what allows us to call spec() in init.lua for each plugin in
    lua/user, just returning the 'M' objects
--]]

-- a global variable (table)
LAZY_PLUGIN_SPEC = {}

-- global function that expects a lazy plugin spec 
-- and add it to the global table declared above
function spec(item)
  table.insert(LAZY_PLUGIN_SPEC, { import = item })
end
