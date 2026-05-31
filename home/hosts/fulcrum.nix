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
      black   = "#303030";
      red     = "#c06060";
      green   = "#70a080";
      yellow  = "#c0a060";
      blue    = "#7090b0";
      magenta = "#9070a0";
      cyan    = "#60a0a8";
      white   = "#e2e2e2";
    };
    bright = {
      black   = "#505050";
      red     = "#d08080";
      green   = "#90c0a0";
      yellow  = "#d4b880";
      blue    = "#90b0d0";
      magenta = "#b090c0";
      cyan    = "#80c0c8";
      white   = "#ffffff";
    };
    dim = {
      black   = "#1a1a1a";
      red     = "#804040";
      green   = "#4a6e58";
      yellow  = "#806840";
      blue    = "#486078";
      magenta = "#604870";
      cyan    = "#406870";
      white   = "#919191";
    };
  };

}
