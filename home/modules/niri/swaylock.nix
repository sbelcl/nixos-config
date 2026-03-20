#
# ~/.nixos/home/modules/niri/swaylock.nix
#
{pkgs, lib, config, ...}: let
  swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
in {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      clock = true;
      indicator = true;
      indicator-radius = 110;
      indicator-thickness = 8;
      effect-blur = "8x5";
      effect-vignette = "0.4:0.6";
      font = "Inter";
      font-size = 28;
      timestr = "%H:%M";
      datestr = "%A, %B %e";

      # Colors — dark, matching the rest of the setup
      color           = "00000000";  # transparent fallback (blur fills it)
      inside-color    = "1e1e1ecc";
      inside-clear-color   = "1e1e1ecc";
      inside-ver-color     = "1e1e1ecc";
      inside-wrong-color   = "1e1e1ecc";
      ring-color      = "7fc8ffaa";
      ring-clear-color     = "7fc8ffaa";
      ring-ver-color       = "7fc8ffff";
      ring-wrong-color     = "dc5050ff";
      line-color           = "00000000";
      line-clear-color     = "00000000";
      line-ver-color       = "00000000";
      line-wrong-color     = "00000000";
      text-color           = "ffffffff";
      text-clear-color     = "ffffffff";
      text-ver-color       = "ffffffff";
      text-wrong-color     = "ff8888ff";
      key-hl-color         = "7fc8ffff";
      bs-hl-color          = "dc5050ff";
      separator-color      = "00000000";
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
  systemd.user.services.swayidle.Unit.ConditionEnvironment = lib.mkForce "NIRI_SOCKET";
  # Force dark GTK4 color scheme so swaync window background is dark not white
  systemd.user.services.swaync.Service.Environment = [
    "GTK_THEME=Adwaita:dark"
    "ADW_DEBUG_COLOR_SCHEME=prefer-dark"
    "GSK_RENDERER=cairo"
  ];

  systemd.user.services.swayosd = {
    Unit.ConditionEnvironment = lib.mkForce "NIRI_SOCKET";
    Service = {
      Environment = [
        "XDG_DATA_DIRS=${pkgs.papirus-icon-theme}/share:${pkgs.adwaita-icon-theme}/share:/run/current-system/sw/share:%h/.local/share"
      ];
      Restart = lib.mkForce "on-failure";
      StartLimitBurst = lib.mkForce 3;
      StartLimitIntervalSec = lib.mkForce 30;
    };
  };

  services.swayosd = {
    enable = true;
    topMargin = 0.85;
    stylePath = ./swayosd-style.css;
  };
}
