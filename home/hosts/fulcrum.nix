#
# ~/.nixos/home/hosts/fulcrum.nix
#
# Fulcrum-specific home overrides (gaming rig)
#
{ pkgs, lib, ... }: {
  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#fulcrum";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@fulcrum";
  };

  # Fulcrum-specific packages not in the shared home config
  home.packages = with pkgs; [
    vscode
    btop
  ];

  # Match Hyprland borders to HyprPanel's matugen monochrome palette
  wayland.windowManager.hyprland.settings.general = {
    "col.active_border"   = lib.mkForce "rgba(e2e2e2ee) rgba(ffffffff) 45deg";
    "col.inactive_border" = lib.mkForce "rgba(39393988)";
  };

}
