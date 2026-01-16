return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false, -- Load immediately to enable navigation at startup
    keys = {
      -- Move between splits/panes
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move Left" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move Down" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move Up" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move Right" },
      
      -- Resize splits/panes
      { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize Left" },
      { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize Down" },
      { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize Up" },
      { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize Right" },
    },
    opts = {
      -- Use the default multiplexer detection (auto-detects Zellij)
      -- or explicitly set it:
      multiplexer_integration = "zellij",
      
      -- Disable default mappings since we defined them manually above
      disable_multiplexer_nav_mappings = false, 
    },
  },
}