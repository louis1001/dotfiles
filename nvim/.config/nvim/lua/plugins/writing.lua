return {
  -- 1. Zen Mode: Press <Leader>z to toggle
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = {
        width = 80, -- Width of the writing area
        options = {
          number = false, -- Hide line numbers
          relativenumber = false,
          signcolumn = "no", -- Hide left column
          foldcolumn = "0", -- Hide fold column
        },
      },
      plugins = {
        gitsigns = { enabled = true }, -- Hide git changes
        tmux = { enabled = true }, -- Hide tmux status bar (if used)
      },
      -- THIS IS THE MAGIC PART
      on_open = function()
        -- 1. Turn off Copilot suggestions
        local status = require("copilot.suggestion").is_visible()
        if status then
          require("copilot.suggestion").dismiss()
        end
        vim.b.copilot_suggestion_auto_trigger = false
        vim.b.copilot_suggestion_hidden = true

        -- 2. (Optional) Turn off diagnostics (red squiggles)
        vim.diagnostic.disable(0)
      end,
      on_close = function()
        -- 1. Turn Copilot suggestions back ON
        vim.b.copilot_suggestion_auto_trigger = true
        vim.b.copilot_suggestion_hidden = false

        -- 2. Turn diagnostics back ON
        vim.diagnostic.enable(0)
      end,
    },
  },

  -- 2. Twilight: Dims inactive text (Optional, nice for focus)
  {
    "folke/twilight.nvim",
    opts = {},
    keys = {
      { "<leader>zt", "<cmd>Twilight<cr>", desc = "Toggle Twilight" },
    },
  },
}
