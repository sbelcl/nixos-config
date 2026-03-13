#
# ~/.nixos/home/modules/niri/swaylock.nix
#
{ pkgs, ... }:
{
  programs = {
    swaylock = {
      enable = true;
      settings = {
        image = "~/.nixos/home/modules/swaylock.png";
        #no-unlock-indicator;
      };
    };
  };
  services = {
    swayidle.enable = true;
    swayosd.enable = true;
  };
}
