#
# ~/.nixos/modules/software/niri.nix
#
{
  pkgs,
  lib,
  config,
  ...
}: {
  #services.displayManager.lightdm.enable = true;
  #services.displayManager.sddm.enable = true;
  #services.displayManager.sddm.wayland.enable = true;

  services.seatd.enable = true;

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr # za Niri (wlroots-based)
      pkgs.xdg-desktop-portal-gtk # file picker, tematski dialogi
      pkgs.xdg-desktop-portal-gnome # file picker, tematski dialogi
    ];
  };
  environment.systemPackages = with pkgs; [libinput];
}
