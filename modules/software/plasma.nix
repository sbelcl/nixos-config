#
# ~/.nixos/modules/software/plasma.nix
#
# KDE Plasma desktop environment - good for gaming and general use
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.desktop.plasma = {
    enable = mkEnableOption "KDE Plasma desktop environment";
  };

  config = mkIf config.desktop.plasma.enable {
    # Enable Plasma 6
    services.desktopManager.plasma6.enable = true;

    # XDG portals for Plasma
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
    };

    # Useful KDE applications
    environment.systemPackages = with pkgs; [
      # KDE apps
      kdePackages.kate
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.spectacle
      kdePackages.konsole
      kdePackages.kcalc

      # System settings extras
      kdePackages.plasma-systemmonitor
      kdePackages.plasma-nm
      kdePackages.plasma-pa

      # File management
      kdePackages.kio-extras
      kdePackages.ffmpegthumbs

      # Gaming integration
      kdePackages.kgamma
    ];

    # Exclude some default Plasma apps that might conflict
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa # media player - might prefer own choice
    ];
  };
}
