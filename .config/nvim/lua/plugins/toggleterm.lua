return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        -- Your toggleterm configuration here
        size = 15,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
      })

      -- Add your terminal keymaps HERE
      local Terminal = require("toggleterm.terminal").Terminal

      -- Cargo Run terminal
      local cargo_run = Terminal:new({
        cmd = "cargo run",
        dir = vim.fn.getcwd(),
        hidden = true,
        direction = "float",
      })

      vim.keymap.set("n", "<leader>rr", function()
        cargo_run:toggle()
      end, { desc = "Run Cargo" })
    end,
  },
}
