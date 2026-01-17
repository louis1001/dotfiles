return {
  -- 1. Base16 Plugin (The Theme Provider)
  {
    "RRethy/nvim-base16",
    lazy = false,
    priority = 1000, -- Load first
    config = function()
      -- Transparency settings
      -- We apply these on the ColorScheme event to ensure they stick
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
          vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
        end,
      })
    end,
  },

  -- 2. Tell LazyVim Core to use our theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "base16-dracula",
    },
  },

  -- 3. Disable default themes to save startup time
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
}
