-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Optimize startup time by disabling unused providers
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Enable spell checking
vim.opt.spell = false
vim.opt.spelllang = { "en_us" }

-- Soft wrapping (wrap at window edge, don't break words)
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Hide the "tilde" ~ characters on empty lines
vim.opt.fillchars = { eob = " " }
