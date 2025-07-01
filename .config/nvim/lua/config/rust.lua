return {
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {
      tools = {
        hover_actions = {
          auto_focus = true, -- Auto-focus the hover window
          border = "rounded", -- Border style
        },
      },
    },
    config = function(_, opts)
      require("rust-tools").setup(opts)
    end,
  },
}
