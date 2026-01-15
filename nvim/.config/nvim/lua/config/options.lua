-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Enable spell checking
vim.opt.spell = true
vim.opt.spelllang = { "en_us" }

-- Soft wrapping (wrap at window edge, don't break words)
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Hide the "tilde" ~ characters on empty lines
vim.opt.fillchars = { eob = " " }
