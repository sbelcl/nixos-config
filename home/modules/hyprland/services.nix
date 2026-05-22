#
# ~/.nixos/home/modules/hyprland/services.nix
#
# Per-session services for Hyprland — mirrors what niri/niri.nix does
# for the Niri session (cliphist, nm-applet).
#
{ pkgs, ... }: {
  # Clipboard history
  systemd.user.services.cliphist-hyprland = {
    Unit = {
      Description = "Clipboard history daemon (Hyprland)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # NetworkManager tray applet
  systemd.user.services.nm-applet-hyprland = {
    Unit = {
      Description = "NetworkManager applet (Hyprland)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    };
    Service = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
