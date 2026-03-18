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
      {
        timeout = 300;
        command = "${swaylock} -f";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events = {
      before-sleep = "${swaylock} -f";
    };
  };

  # Only start swayidle and swayosd inside a Niri session —
  # Plasma handles locking and OSD itself via kscreenlocker/plasma-workspace.
  systemd.user.services.swayidle.Unit.ConditionEnvironment = "NIRI_SOCKET";
  systemd.user.services.swayosd.Unit.ConditionEnvironment = "NIRI_SOCKET";

  services.swayosd.enable = true;
}
