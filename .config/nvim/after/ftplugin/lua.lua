-- FIXME I don't know why this should be necessary. The global setting
-- in 'plugin/options.lua' is effective when starting nvim in a lua file,
-- but if I start with multiple files and then switch to a lua buffer,
-- the shiftwidth gets changed to 8. I haven't been able to track down where
-- that happens
vim.opt.shiftwidth = 2
