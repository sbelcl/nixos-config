#
# ~/.nixos/home/modules/hyprland/hyprpanel.nix
#
{ pkgs, inputs, ... }: let
  hp = inputs.hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = [ hp ];

  # hyprlauncher — Hyprland-native app launcher.
  # Run as a daemon (-d) so it's pre-loaded and appears instantly on keypress.
  # Styling is not available in v0.1.5 (only window_size is exposed).
  services.hyprlauncher = {
    enable = true;
    settings = {
      general.grab_focus = true;
      cache.enabled = true;
      ui.window_size = "560 380";
      finders = {
        desktop_icons = true;
        math_prefix = "=";
      };
    };
  };

  # Start HyprPanel only in Hyprland sessions.
  # HyprPanel is an AGS-based bar + notification centre — it replaces
  # both a bar (waybar) and a notification daemon (swaync) for Hyprland.
  systemd.user.services.hyprpanel = {
    Unit = {
      Description = "HyprPanel bar and notification daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    };
    Service = {
      ExecStart = "${hp}/bin/hyprpanel";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
