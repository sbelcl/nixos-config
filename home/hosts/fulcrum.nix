#
# ~/.nixos/home/hosts/fulcrum.nix
#
# Fulcrum-specific home overrides (gaming rig)
#
{pkgs, lib, ...}: {
  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#fulcrum";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@fulcrum";
  };

  # Fulcrum-specific packages not in the shared home config
  home.packages = with pkgs; [
    vscode
    btop
  ];

  nixpkgs.config.allowUnfreePredicate = lib.mkForce (pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "kiro"
      "google-chrome"
      "discord"
      "telegram-desktop"
      "vscode"
    ]);
}
