#
# ~/.nixos/home/modules/hyprland/hyprpanel.nix
#
{ pkgs, inputs, ... }: let
  hp = inputs.hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = [ hp ];

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
