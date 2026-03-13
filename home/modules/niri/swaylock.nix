#
# ~/.nixos/home/modules/niri/swaylock.nix
#
{pkgs, ...}: let
  swaylock = "${pkgs.swaylock}/bin/swaylock";
in {
  programs.swaylock = {
    enable = true;
    settings = {
      image = "~/.nixos/home/modules/swaylock.png";
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      # Lock screen after 5 minutes of inactivity
      {
        timeout = 300;
        command = "${swaylock} -f";
      }
      # Turn off displays after 10 minutes
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events = [
      # Lock before the system goes to sleep
      {
        event = "before-sleep";
        command = "${swaylock} -f";
      }
    ];
  };

  services.swayosd.enable = true;
}
