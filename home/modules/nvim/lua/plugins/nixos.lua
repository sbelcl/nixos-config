-- Mason, disabled on purpose.
--
-- Mason installs language servers and formatters as prebuilt, dynamically
-- linked binaries from the internet. NixOS has no /lib64/ld-linux-x86-64.so.2,
-- so they do not run at all:
--
--   $ ~/.local/share/nvim/mason/bin/tree-sitter --version
--   Could not start dynamically linked executable
--
-- It installed shfmt, stylua and tree-sitter on first sync, and all three were
-- dead on arrival. The same tools now come from nixpkgs and sit on PATH, which
-- is where conform.nvim, nvim-lint and lspconfig look for them anyway — see
-- home/modules/neovim.nix. Add a tool there rather than through :Mason.
--
-- Names are mason-org/*, not the older williamboman/*, matching LazyVim 16.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}
