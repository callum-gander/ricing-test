-- Catppuccin Latte (warm light) as the LazyVim colorscheme — the closest
-- editorial-paper fit that ships with the already-installed catppuccin plugin.
-- For a warmer, lower-contrast "paper" feel, swap to melange instead:
--   { "savq/melange-nvim", name = "melange", init = function() vim.o.background = "light" end },
--   { "LazyVim/LazyVim", opts = { colorscheme = "melange" } },
return {
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "latte" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
