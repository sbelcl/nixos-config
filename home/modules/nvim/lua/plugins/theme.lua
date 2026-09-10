-- The editor half of the wallpaper theme.
--
-- matugen writes ~/.config/nvim/matugen-base16.lua on every theme change (see
-- the nvim-base16 template in home/modules/matugen.nix), and mini.base16 turns
-- those sixteen colours into the full set of highlight groups. So SUPER+SHIFT+W
-- retints Neovim along with Alacritty, the bar, rofi, GTK and btop.
--
-- The file is generated, so it is deliberately not vendored here: it does not
-- exist until matugen has run once, and pcall is what keeps a fresh checkout
-- from erroring into a config with no colours at all.
local palette_file = vim.fn.expand("~/.config/nvim/matugen-base16.lua")

return {
  {
    "echasnovski/mini.base16",
    lazy = false,
    priority = 1000, -- ahead of everything that sets highlights of its own
    config = function()
      local ok, palette = pcall(dofile, palette_file)
      if ok and type(palette) == "table" and palette.base00 then
        require("mini.base16").setup({ palette = palette })
      else
        -- matugen has not run yet. tokyonight ships with LazyVim, so this is
        -- a colourscheme rather than the default grey.
        pcall(vim.cmd.colorscheme, "tokyonight")
      end
    end,
  },

  -- LazyVim sets its own colorscheme after plugins load, which would undo the
  -- above. An empty function is how it is told the choice is already made.
  { "LazyVim/LazyVim", opts = { colorscheme = function() end } },
}
