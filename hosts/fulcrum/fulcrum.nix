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
    unrar # required by gamma-launcher to extract STALKER GAMMA mod archives
    obs-studio
    kdePackages.kdenlive
    nvtopPackages.nvidia
  ];

  # ==========================================================================
  # Storage
  # ==========================================================================

  # Bulk storage HDD — downloads, media, backups
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/d7370172-9b2e-4b90-933f-2183d5a02540";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" ];
  };

  # Games NVMe drive (XFS) — permanent mount for Steam library
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/89606cba-0dcc-4fb6-ae26-fc419a66e048";
    fsType = "xfs";
    options = [ "nofail" "x-systemd.automount" ];
  };

  # ==========================================================================
  # System
  # ==========================================================================

  system.stateVersion = "25.11";
}
