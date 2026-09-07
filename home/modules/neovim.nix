#
# ~/.nixos/home/modules/neovim.nix
#
# LazyVim, as its own config tree rather than a generated init.lua.
#
# The config lives in ./nvim (the upstream LazyVim starter, vendored) and is
# linked file-by-file into ~/.config/nvim. `recursive = true` is what makes
# that work: it symlinks each file individually instead of the directory, so
# ~/.config/nvim is a real writable directory. lazy.nvim needs that — it
# writes lazy-lock.json there, and :LazyExtras writes lazyvim.json. Link the
# directory itself and both fail against a read-only store path.
#
# The consequence is the usual one for this repo: edit the files under
# home/modules/nvim and run updhome. Editing them through ~/.config/nvim edits
# the store symlink target, which is read-only.
#
# Plugins themselves are not Nix-managed. lazy.nvim clones them into
# ~/.local/share/nvim at first start and `:Lazy update` moves them; the pinned
# set is whatever lazy-lock.json says. Making those declarative means nixvim or
# similar, which is a different thing from running LazyVim.
#
{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    # Ruby's provider goes with the old config: nothing in LazyVim uses it and
    # it pulls a full ruby into the closure. Set explicitly rather than left to
    # the default — home.stateVersion here predates 26.05, so the default is
    # still the legacy `true` and dropping the line would keep ruby.
    withRuby = false;
    withPython3 = true;
    withNodeJs = true;
  };

  # The toolchain LazyVim shells out to. git, gcc, ripgrep, fd, nodejs and
  # unzip are already in packages.nix and not repeated here.
  #
  # The rest replace what mason would otherwise download — see
  # ./nvim/lua/plugins/nixos.lua for why mason cannot work here. Whatever
  # mason would install goes in this list instead, and lands on PATH where
  # conform.nvim, nvim-lint and lspconfig already look.
  home.packages = with pkgs; [
    gnumake # telescope-fzf-native and friends build with it
    tree-sitter # nvim-treesitter is on its `main` branch, which compiles
    # parsers with the CLI rather than shipping them
    stylua # conform: lua
    shfmt # conform: sh
    lua-language-server # the one server LazyVim configures out of the box
  ];

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
