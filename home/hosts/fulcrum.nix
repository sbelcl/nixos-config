#
# ~/.nixos/home/hosts/fulcrum.nix
#
# Fulcrum-specific overrides (gaming rig)
#
{...}: {
  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#fulcrum";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@fulcrum";
  };
}
