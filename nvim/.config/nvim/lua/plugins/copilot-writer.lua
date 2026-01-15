return {
  -- 1. COILOT ENGINE (Restored to default behavior)
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true, -- ENABLED globally (good for coding)
        keymap = {
          accept = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      filetypes = {
        markdown = true, -- We keep it enabled so Chat can read the file
        help = false,
        ["*"] = true,
      },
    },
  },

  -- 2. COPILOT CHAT (Keep your writer prompts)
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {
      show_help = false,
      prompts = {
        -- (Keep your custom prompts here from the previous step)
        Proofread = {
          prompt = "/COPILOT_REVIEW\n\nReview the selected text for spelling, grammar, and typos. Do not rewrite the whole text. Just list the errors you found with a brief suggestion for each.",
          description = "Proofread",
        },
        Structure = {
          prompt = "Analyze the text I have written. Suggest a logical outline for the next 3 sections to ensure a good flow. Do not write the content, just the headers and bullet points.",
          description = "Structure Advisor",
        },
        ToneCheck = {
          prompt = "Analyze the tone of the selected text. It should be 'Professional Technical' but 'Approachable'. Highlight any words that are too academic, too slangy, or passive voice. Suggest 1 alternative for each.",
          description = "Tone Check",
        },
        IdeaGen = {
          prompt = "Read my current draft. Suggest 3 unique 'angles' or 'missing perspectives' I haven't covered yet that would make this article more valuable to a developer.",
          description = "Idea Generator",
        },
      },
    },
  },
}
