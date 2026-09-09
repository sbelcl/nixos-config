#
# ~/.nixos/modules/settings/locales.nix
#
{
  config,
  pkgs,
  ...
}: {
  # Set your time zone
  time.timeZone = "Europe/Ljubljana";

  # Select internationalisation properties
  i18n.defaultLocale = "sl_SI.UTF-8";
  # Mirrored in home/modules/session-variables.nix, which trims its own copy of
  # the locale archive to the same two. The home flake is standalone, so it
  # cannot read this value, and its LOCALE_ARCHIVE_2_27 is the one glibc
  # actually uses in a user session — change one list and the other has to
  # follow, or the session quietly keeps whatever it had.
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "sl_SI.UTF-8/UTF-8"
  ];

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sl_SI.UTF-8";
    LC_IDENTIFICATION = "sl_SI.UTF-8";
    LC_MEASUREMENT = "sl_SI.UTF-8";
    LC_MONETARY = "sl_SI.UTF-8";
    LC_NAME = "sl_SI.UTF-8";
    LC_NUMERIC = "sl_SI.UTF-8";
    LC_PAPER = "sl_SI.UTF-8";
    LC_TELEPHONE = "sl_SI.UTF-8";
    LC_TIME = "sl_SI.UTF-8";
  };

  # Console keymap
  console.keyMap = "slovene";

  # Configure X11 keymap
  services.xserver.xkb = {
    layout = "si";
    variant = "";
  };
}
