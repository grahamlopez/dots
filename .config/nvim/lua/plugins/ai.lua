return {

  {
    -- https://github.com/frankroeder/parrot.nvim
    "frankroeder/parrot.nvim",
    enabled = true,
    lazy = true,
    event = "VeryLazy",
    dependencies = { "ibhagwan/fzf-lua", "nvim-lua/plenary.nvim" },
    cond = os.getenv("PERPLEXITY_API_KEY") ~= nil,
    opts = {
      -- Providers must be explicitly set up to make them available.
      providers = {
        pplx = {
          name = "pplx", -- ISSUE: remove this footgun - must be the same as the parent table name
          api_key = os.getenv("PERPLEXITY_API_KEY"),
          endpoint = "https://api.perplexity.ai/chat/completions",
          params = {
            chat = { temperature = 1.1, top_p = 1 },
            command = { temperature = 1.1, top_p = 1 },
          },
          topic = {
            model = "sonar-medium-chat",
            params = { max_completion_tokens = 64 },
          },
          models = {
            "sonar-pro", -- Advanced search, flagship model
            "sonar", -- Lightweight search model
            "sonar-reasoning-pro", -- Premier reasoning model with Chain of Thought
            "sonar-reasoning", -- Fast real-time reasoning model
            "sonar-deep-research", -- Expert-level research model
            "r1-1776", -- Offline chat model (no web search)
            "sonar-small-online", -- Online model, fast, web-enabled
            "sonar-medium-online", -- Online model, balanced, web-enabled
            "sonar-small-chat", -- Offline chat model, fast
            "sonar-medium-chat", -- Offline chat model, balanced
            "mistral-7b", -- Open-source, balanced for various tasks
            "codellama-34b", -- Specialized for code-related tasks
            "llama-2-70b", -- Large model, broad knowledge
          },
        },
      },
    },
  },

  {
    -- https://github.com/olimorris/codecompanion.nvim
    "olimorris/codecompanion.nvim",
    enabled = false,
    lazy = true,
    event = "VeryLazy",
  },

  {
    -- https://github.com/yetone/avante.nvim
    "yetone/avante.nvim",
    enabled = false,
    lazy = true,
    event = "VeryLazy",
  },

  {
    -- https://github.com/ravitemer/mcphub.nvim
    "ravitemer/mcphub.nvim",
    enabled = false,
    lazy = true,
    event = "VeryLazy",
  },
}
