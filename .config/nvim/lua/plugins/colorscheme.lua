return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },
  { "lunarvim/darkplus.nvim" },
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "darkplus",
    },
  },
}
