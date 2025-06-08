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
          -- used for summarizing chats. save some moneys
          -- topic = {
          --   model = "r1-1776",
          --   params = { max_completion_tokens = 64 },
          -- },
          models = { -- https://docs.perplexity.ai/models/model-cards
            "sonar-pro", -- Advanced search, flagship model
            "sonar", -- Lightweight search model
            "sonar-reasoning-pro", -- Premier reasoning model with Chain of Thought
            "sonar-reasoning", -- Fast real-time reasoning model
            "sonar-deep-research", -- Expert-level research model
            "r1-1776", -- Offline chat model (no web search)
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

  {
    -- https://github.com/azorng/goose.nvim
  },
}
