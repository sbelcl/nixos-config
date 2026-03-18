#
# ~/.nixos/hosts/fulcrum/fulcrum.nix
#
# Gaming rig — SDDM + Plasma, Hyprland, Xmonad, Niri
#
{
  pkgs,
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
  # Display Manager and Desktop Environments
  # ==========================================================================

  # Disable greetd (flanker-specific auto-login to Niri)
  displayManager.greetd.enable = false;

  # SDDM — lets user choose between Plasma, Hyprland, Xmonad, Niri at login
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Hyprland (defined as custom module in modules/software/hyprland.nix)
  desktop.hyprland.enable = true;

  # Xmonad
  services.xserver = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  # Niri is enabled unconditionally via modules/software/niri.nix

  # ==========================================================================
  # Gaming
  # ==========================================================================

  # Steam hardware support (controllers, etc.)
  hardware.steam-hardware.enable = true;

  # Gaming packages (not in home config)
  environment.systemPackages = with pkgs; [
    lutris
    heroic
    protonup-qt
    wine
    winetricks
    obs-studio
    kdePackages.kdenlive
    nvtopPackages.nvidia
  ];

  # ==========================================================================
  # System
  # ==========================================================================

  system.stateVersion = "25.11";
}
