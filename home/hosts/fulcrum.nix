#
# ~/.nixos/home/hosts/fulcrum.nix
#
# Fulcrum-specific home overrides (gaming rig, Hyprland-only)
#
{ pkgs, config, lib, ... }: {
  # The Hyprland stack, the same set flanker imports minus battery.nix —
  # UPower alerts on a desktop with no battery would be a module reading a
  # device that isn't there.
  imports = [
    ../modules/hyprland/hyprland.nix
    ../modules/rofi.nix              # launcher — KRunner left with Plasma
    ../modules/fuzzel.nix            # secondary launcher (Wayland-native)
    ../modules/matugen.nix           # wallpaper→color scheme sync (templates)
    ../modules/theme.nix             # theme source + light/dark + wallpaper-next
  ];

  # local.bar is deliberately not set: both options default to false, which is
  # what this machine wants. No battery, and brightness here is DDC/CI through
  # ddcutil on i2c-4 (see hosts/fulcrum/fulcrum.nix) — Wayle's backlight module
  # drives /sys/class/backlight via brightnessctl and cannot reach it. The bar
  # composes down to systray/bluetooth/network/microphone/volume/dashboard.
  #
  # Caveat carried over from wayle.nix: the bluetooth module is unconditional,
  # while fulcrum force-disables hardware.bluetooth (no radio in this box). It
  # will render an inert control until that module gets the same treatment as
  # battery and backlight.

  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#fulcrum";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@fulcrum";
  };

  # Fulcrum-specific packages not in the shared home config
  home.packages = with pkgs; [
    vscode
  ];

  # Kept through the Plasma removal, not after it. Plasma rewrites these on
  # every session start, turning HM's symlinks into real files and blocking the
  # next updhome; the files it already wrote are still on disk, so the first
  # switch after the migration still needs them cleared. Once fulcrum has
  # booted into Hyprland and switched cleanly, nothing writes them any more and
  # this block can go.
  #
  # The last three were added during the migration itself, after they blocked a
  # switch that the first four sailed through:
  #
  #   gtk-3.0/gtk.css + colors.css  kde-gtk-config writes a 21-byte gtk.css
  #                                 that @imports its own colors.css. The GTK4
  #                                 equivalent was already listed; the GTK3 one
  #                                 was simply missed.
  #   mimeapps.list                 rewritten whenever Plasma touches default
  #                                 applications. HM owns it via xdg.mimeApps
  #                                 (home/modules/packages.nix), so deleting
  #                                 the stray copy loses nothing declared.
  #
  # Deleting rather than backing up is deliberate: `-b backup` refuses to run a
  # second time once a .backup exists, so on a machine that keeps regenerating
  # these it fails on the *previous* backup instead of the file, and the plain
  # `updhome` alias carries no -b at all.
  home.activation.stripPlasmaGtkRewrites =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f \
        "$HOME/.gtkrc-2.0" \
        "$HOME/.config/gtk-3.0/settings.ini" \
        "$HOME/.config/gtk-4.0/settings.ini" \
        "$HOME/.config/gtk-4.0/gtk.css" \
        "$HOME/.config/gtk-3.0/gtk.css" \
        "$HOME/.config/gtk-3.0/colors.css" \
        "$HOME/.config/mimeapps.list"
    '';
}
