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
  # Storage
  # ==========================================================================

  # Games NVMe drive (NTFS) — permanent mount for Steam library
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/1AE8D3F9E8D3D0DD";
    fsType = "ntfs3"; # kernel NTFS driver, better performance than ntfs-3g
    options = [
      "uid=1000"       # imnos
      "gid=100"        # users
      "umask=0022"
      "nofail"         # don't block boot if drive is missing
      "x-systemd.automount"  # mount on first access, not at boot
    ];
  };

  # ==========================================================================
  # System
  # ==========================================================================

  system.stateVersion = "25.11";
}
