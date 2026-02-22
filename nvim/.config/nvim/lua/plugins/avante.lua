return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- false para usar siempre la versión 'main' (recomendado por Avante)
  build = "make", -- Importante: Avante necesita compilar un pequeño binario de Rust/C
  opts = {
    -- Le decimos que use nuestro proveedor personalizado 'ollama'
    provider = "ollama",
    providers = {
      ollama = {
        __inherited_from = "openai",
        api_key_name = "",
        endpoint = "http://127.0.0.1:11434/v1",
        model = "qwen3-coder:8b",
        timeout = 30000, -- 30 segundos
        temperature = 0,
        max_tokens = 4096,
      },
    },
    -- Configuración de comportamiento (opcional)
    behaviour = {
      auto_suggestions = false, -- Ponlo en true si quieres sugerencias tipo ghost-text
    },
  },
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- Dependencias opcionales para mejorar la UI
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
    {
      -- Soporte para pegar imágenes
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = { insert_mode = true },
          use_absolute_path = true,
        },
      },
    },
    {
      -- Para que el markdown del chat se vea bonito
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
