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

  # Alacritty — monochrome theme matching HyprPanel matugen palette
  # #131313 bg · #e2e2e2/#ffffff fg · all ANSI colors as grey steps
  programs.alacritty.settings.colors = lib.mkForce {
    primary = {
      background      = "#131313";
      foreground      = "#e2e2e2";
      dim_foreground  = "#919191";
      bright_foreground = "#ffffff";
    };
    cursor = {
      text   = "#131313";
      cursor = "#e2e2e2";
    };
    vi_mode_cursor = {
      text   = "#131313";
      cursor = "#c6c6c6";
    };
    selection = {
      text       = "CellForeground";
      background = "#393939";
    };
    normal = {
      black   = "#131313";
      red     = "#919191";
      green   = "#a0a0a0";
      yellow  = "#b4b4b4";
      blue    = "#c6c6c6";
      magenta = "#919191";
      cyan    = "#b4b4b4";
      white   = "#e2e2e2";
    };
    bright = {
      black   = "#393939";
      red     = "#b4b4b4";
      green   = "#c0c0c0";
      yellow  = "#cccccc";
      blue    = "#d8d8d8";
      magenta = "#b4b4b4";
      cyan    = "#d8d8d8";
      white   = "#ffffff";
    };
    dim = {
      black   = "#0a0a0a";
      red     = "#606060";
      green   = "#707070";
      yellow  = "#808080";
      blue    = "#919191";
      magenta = "#606060";
      cyan    = "#808080";
      white   = "#b4b4b4";
    };
  };

}
