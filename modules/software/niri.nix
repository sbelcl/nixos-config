#
# ~/.nixos/modules/software/niri.nix
#
{
  pkgs,
  lib,
  ...
}: {
  #services.displayManager.lightdm.enable = true;
  #services.displayManager.sddm.enable = true;
  #services.displayManager.sddm.wayland.enable = true;

  services.seatd.enable = true;

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    # wlr portal handles screen capture/sharing on wlroots compositors (Niri)
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk  # file picker, colour chooser, etc.
    ];
    # Tell the portal chooser which backend to use per-interface on Niri
    config.niri = {
      default = lib.mkForce [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast"  = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot"  = [ "wlr" ];
    };
  };
  environment.systemPackages = with pkgs; [libinput];

  # swayosd-libinput-backend runs on the system D-Bus (not session bus) —
  # it needs root to own org.erikreider.swayosd on the system bus.
  # Install the D-Bus policy and udev rules from the package, then run as a system service.
  services.dbus.packages = [pkgs.swayosd];
  services.udev.packages = [pkgs.swayosd];

  systemd.services.swayosd-libinput-backend = {
    description = "SwayOSD libinput backend for lock key OSD";
    wantedBy = ["graphical.target"];
    after    = ["graphical.target"];
    partOf   = ["graphical.target"];
    serviceConfig = {
      Type    = "dbus";
      BusName = "org.erikreider.swayosd";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
      Restart = "on-failure";
    };
  };
}
