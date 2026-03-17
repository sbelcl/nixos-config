#
# ~/.nixos/home/hosts/flanker.nix
#
# Flanker-specific overrides (laptop)
#
{...}: {
  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#flanker";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@flanker";
  };
}
