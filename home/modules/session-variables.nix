#
# ~/.nixos/home/modules/session-variables.nix
#
{pkgs, ...}: {
  # Locale archive, trimmed to the same two locales the system declares in
  # modules/settings/locales.nix. Keep the lists in step — see the note there.
  #
  # Without this, the session gets *every* locale glibc ships. home-manager
  # defines `nixosConfig.i18n.glibcLocales or pkgs.glibcLocales`, and as a
  # standalone flake there is no nixosConfig to read, so the fallback wins:
  # 223 MB of archive against the 3.1 MB NixOS builds from i18n.supportedLocales.
  #
  # It is not a harmless duplicate either — it is the archive that actually
  # gets used. nixpkgs patches glibc to prefer the version-suffixed variable,
  # and home-manager sets LOCALE_ARCHIVE_2_27 (~/.config/environment.d), which
  # outranks the LOCALE_ARCHIVE that NixOS points at its trimmed build. Before
  # this, `LC_ALL=ja_JP.UTF-8 date +%B` answered in Japanese on a system
  # declaring exactly two locales.
  #
  # The list cannot be shared with the system module: that file is outside this
  # flake's root, and a path escaping home/ only resolves by accident of the
  # repo being a git tree (see home/modules/hyprland/hyprpaper.nix).
  i18n.glibcLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = [
      "en_US.UTF-8/UTF-8"
      "sl_SI.UTF-8/UTF-8"
    ];
  };

  home.sessionVariables = {
    # User preferences
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "yandex-browser-beta";
    TERMINAL = "alacritty";

    # Cursor
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";

    # Native Wayland rendering for Electron apps (VSCode, Discord, Obsidian…).
    # The variable is NIXOS_OZONE_WL; this read NIXOS_OZONE_LAYER, which is not
    # a thing, so the setting did nothing. It went unnoticed because
    # modules/settings/env.nix sets the correct name system-wide — this one
    # only matters if the home config is ever used on a non-NixOS host.
    NIXOS_OZONE_WL = "1";

    # Native Wayland for Firefox
    MOZ_ENABLE_WAYLAND = "1";

    # LIBVA_DRIVER_NAME is deliberately unset: flanker's AMD iGPU drives the
    # session and autodetection picks the right driver. A host whose compositor
    # runs on NVIDIA sets it in its own host file.
  };

  xdg.userDirs.setSessionVariables = true;

  # Propagate cursor into the systemd user environment (picked up by Wayland apps)
  systemd.user.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # Add user bin directory to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
