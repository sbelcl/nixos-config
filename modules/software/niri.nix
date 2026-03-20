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
}
