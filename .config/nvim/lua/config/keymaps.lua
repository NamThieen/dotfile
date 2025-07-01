-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Rust-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    local map = vim.keymap.set
    local opts = { buffer = true }

    -- Run cargo build
    map("n", "<leader>cb", "<cmd>!cargo build<cr>", opts)

    -- Run cargo run
    map("n", "<leader>ct", "<cmd>!cargo run -q --release<cr>", opts)

    -- Rust-analyzer hover actions
    map("n", "K", "<cmd>RustHoverActions<cr>", opts)
  end,
})
vim.keymap.set("n", "<leader>rr", function()
  local term = require("toggleterm.terminal").Terminal
  local run_cmd = term:new({
    cmd = "cargo run",
    dir = vim.fn.getcwd(),
    direction = "horizontal",
    size = 15,
    close_on_exit = false, -- Keep terminal open
  })
  run_cmd:toggle()
end, { desc = "Run in dedicated terminal" })
vim.keymap.set("n", "<leader>rc", function()
  vim.cmd("split | terminal")
  vim.api.nvim_feedkeys("cd " .. vim.fn.getcwd() .. " && cargo run\n", "n", false)
end, { desc = "Interactive cargo run" })
