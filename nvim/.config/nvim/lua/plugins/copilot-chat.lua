return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary", -- CopilotChat often pushes fixes to canary branch first
    dependencies = {
      { "nvim-lua/plenary.nvim" }, -- For file utilities
      { "nvim-telescope/telescope.nvim" }, -- For our custom picker
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    -- 'opts' handles the settings table passed to setup()
    opts = function(_, opts)
      opts.mappings = {
        complete = { insert = "", normal = "" }, -- Disable default completion if you want
        submit_prompt = { normal = "<CR>", insert = "<C-CR>" },
      }

      opts.contexts = opts.contexts or {}

      -- 1. Custom Context: Read Project Files (The "Agent" Helper)
      -- This allows prompts to use 'project_files' as a context source
      opts.contexts.project_files = {
        input = function(callback)
          local cmd = "git ls-files | head -n 500" -- Limit to avoid huge context
          local handle = io.popen(cmd)
          if handle then
            local result = handle:read("*a")
            handle:close()
            callback(result)
          else
            callback("Error reading project files")
          end
        end,
        resolve = function(input)
          return {
            content = "Here is the current project file structure:\n" .. input,
            filename = "ProjectMap",
            filetype = "text",
          }
        end,
      }

      -- 2. Prompt Loader Logic (Your .github/prompts parser)
      -- (Simplified for brevity, insert your full parser function here)
      -- ...

      return opts
    end,

    -- 'config' allows us to run imperative code AFTER the plugin loads
    config = function(_, opts)
      local chat = require("CopilotChat")

      -- 1. Initialize the plugin with the options defined above
      chat.setup(opts)

      -- 2. Define the Telescope Picker for "Add File to Context"
      -- This is the custom imperative code that MUST go in config()
      vim.keymap.set("n", "<leader>aif", function()
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local builtin = require("telescope.builtin")

        builtin.find_files({
          prompt_title = "Add File to Copilot Context",
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                -- Open Chat window if closed
                chat.open()
                -- Wait slightly for buffer to be ready, then insert
                vim.defer_fn(function()
                  local filename = selection.value
                  -- Use the #file: command syntax which CopilotChat natively understands
                  -- or just paste the filename if you are using custom context logic
                  local text_to_insert = " #file:" .. filename .. " "
                  vim.api.nvim_put({ text_to_insert }, "c", true, true)
                end, 100)
              end
            end)
            return true
          end,
        })
      end, { desc = "Add File to Chat Context" })

      -- 3. (Optional) Any other custom user commands
      vim.api.nvim_create_user_command("CopilotDiff", function(args)
        chat.ask(args.args, { selection = require("CopilotChat.select").visual })
      end, { nargs = "*", range = true })
    end,
  },
}
