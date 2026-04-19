#
# ~/.nixos/hosts/fulcrum/fulcrum.nix
#
# Gaming rig — SDDM + Plasma, Hyprland, Xmonad, Niri
#
{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ./hardware
    ../../modules/software
    ../../modules/settings
    inputs.comfyui-nix.nixosModules.default
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
    ddcutil # DDC/CI monitor brightness control
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
  # ComfyUI — image & video generation (RTX 3080 Ti, 12GB VRAM)
  # Access at http://localhost:8188
  # Models stored on bulk storage HDD to save NVMe space
  # ==========================================================================
  services.comfyui = {
    enable        = true;
    gpuSupport    = "cuda";
    enableManager = true;   # ComfyUI Manager for installing custom nodes
    port          = 8188;
    dataDir       = "/mnt/storage/comfyui";
  };

  # ==========================================================================
  # System
  # ==========================================================================

  # DDC/CI monitor brightness control
  # ddcci-backlight creates a /sys/class/backlight device from DDC/CI
  # which lets standard tools (vibepanel, brightnessctl) control brightness
  hardware.i2c.enable = true;
  users.users.imnos.extraGroups = [ "i2c" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
  boot.kernelModules = [ "ddcci" "ddcci-backlight" ];
  # DDC/CI backlight — two chained udev rules:
  # Rule 1: when i2c-4 bus appears, register the ddcci i2c client at 0x37
  # Rule 2: when that client (4-0037) appears, bind the ddcci driver
  #         → ddcci-backlight then creates /sys/class/backlight/ddcci4
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="i2c-dev", KERNEL=="i2c-4", \
      RUN+="${pkgs.bash}/bin/sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/i2c-4/new_device'"
    ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="4-0037", \
      RUN+="${pkgs.bash}/bin/sh -c 'echo 4-0037 > /sys/bus/i2c/drivers/ddcci/bind'"
  '';

  # ==========================================================================
  # NFS — share /mnt/storage with flanker
  # ==========================================================================
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/storage  192.168.43.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)
  '';
  networking.firewall.allowedTCPPorts = [ 111 2049 ];  # portmapper + NFS
  networking.firewall.allowedUDPPorts = [ 111 2049 ];

  system.stateVersion = "25.11";
}
