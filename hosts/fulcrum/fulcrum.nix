#
# ~/.nixos/hosts/fulcrum/fulcrum.nix
#
# Gaming rig configuration with SDDM + Plasma, Niri, and Hyprland
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware
    ../../modules/software
    ../../modules/settings
  ];

  # Hostname
  networking.hostName = "fulcrum";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel for best gaming support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Allow unfree packages (NVIDIA drivers, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Enable experimental features
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # ==========================================================================
  # Display Manager and Desktop Environment
  # ==========================================================================

  # Disable greetd (used on flanker for Niri-only setup)
  displayManager.greetd.enable = false;

  # Enable SDDM (good integration with Plasma)
  displayManager.sddm.enable = true;

  # Enable KDE Plasma as default desktop
  desktop.plasma.enable = true;

  # Enable Hyprland as alternative WM
  desktop.hyprland.enable = true;

  # Niri is already enabled via modules/software/niri.nix

  # ==========================================================================
  # Gaming and Media
  # ==========================================================================

  # Steam is already enabled in modules/software/steam.nix

  # Additional gaming packages
  environment.systemPackages = with pkgs; [
    # Core tools
    wget
    curl
    git

    # Gaming
    lutris
    heroic
    protonup-qt
    wine
    winetricks

    # Media creation
    obs-studio
    kdePackages.kdenlive
    gimp
    krita
    audacity
    blender

    # Development
    vscode
    neovim

    # System monitoring
    btop
    nvtopPackages.nvidia

    #AI
    claude-code
  ];

  # Enable Steam hardware support
  hardware.steam-hardware.enable = true;

  # ==========================================================================
  # System
  # ==========================================================================

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.11";
}
