#
# ~/.nixos/home/modules/hyprland/services.nix
#
# Per-session services for Hyprland — mirrors what niri/niri.nix does
# for the Niri session (cliphist, nm-applet).  nm-applet is intentionally
# omitted here; HyprPanel handles network via AstalNetwork directly.
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

  # nm-applet omitted — HyprPanel provides its own network widget via
  # AstalNetwork (direct NM D-Bus), so a separate tray applet is redundant
  # and causes GTK assertion spam during Wayland session startup.
}
