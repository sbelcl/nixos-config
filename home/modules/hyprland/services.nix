#
# ~/.nixos/home/modules/hyprland/services.nix
#
# Per-session services for Hyprland. All gated on HYPRLAND_INSTANCE_SIGNATURE
# so they don't fire under Plasma (fulcrum), which has its own equivalents.
# nm-applet is intentionally omitted — HyprPanel handles network via
# AstalNetwork directly.
#
{ pkgs, lib, ... }: {
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

  # Polkit agent — GUI privilege prompts (mounting drives, etc.)
  systemd.user.services.polkit-gnome = {
    Unit = {
      Description = "Polkit GNOME authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      # Kill any orphan instance (e.g. from a previous rebuild) then wait for
      # polkitd to clear the registration before we register again.
      ExecStartPre = [
        "-${pkgs.procps}/bin/pkill -f polkit-gnome-authentication-agent-1"
        "${pkgs.coreutils}/bin/sleep 0.5"
      ];
      Restart = "no";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # USB auto-mount
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };
  systemd.user.services.udiskie.Unit.ConditionEnvironment =
    lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";

  # Night light — reduce blue light after sunset (Ljubljana ~46°N 14°E)
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 46.05;
    longitude = 14.51;
    temperature = {
      day = 6500;
      night = 3500;
    };
  };
  systemd.user.services.gammastep.Unit.ConditionEnvironment =
    lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
}
