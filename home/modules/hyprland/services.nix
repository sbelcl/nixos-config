#
# ~/.nixos/home/modules/hyprland/services.nix
#
# Per-session services for Hyprland. All gated on HYPRLAND_INSTANCE_SIGNATURE
# so they don't fire under Plasma (fulcrum), which has its own equivalents.
# nm-applet is intentionally omitted — HyprPanel handles network via
# AstalNetwork directly.
#
{ pkgs, lib, ... }: let
  # udiskie fires its event hook for every device event (added, mounted,
  # removed, ...), so the script filters for device_mounted itself. It runs
  # ranger in a throwaway Alacritty under the same --class the SUPER+R bind
  # uses, so one float rule in hyprland/config.nix covers both.
  #
  # {mount_path} is not in udiskie's documented placeholder list ({event},
  # {device_presentation}, {id_uuid}) but works: prompt.py builds the format
  # args with getattr(device, attr), so any device attribute is available, and
  # udisks2.py defines mount_path.
  usb-ranger = pkgs.writeShellScriptBin "usb-ranger" ''
    [ "$1" = "device_mounted" ] || exit 0
    [ -n "''${2:-}" ] && [ -d "$2" ] || exit 0
    exec ${pkgs.alacritty}/bin/alacritty --class ranger -e ${pkgs.ranger}/bin/ranger "$2"
  '';
in {
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

  # USB auto-mount — pops ranger open on the new mount point
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
    settings.program_options.event_hook =
      "${usb-ranger}/bin/usb-ranger {event} {mount_path}";
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
