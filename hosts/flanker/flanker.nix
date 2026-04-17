#
# ~/.nixos/hosts/flanker/flanker.nix
#
# Laptop with hybrid NVIDIA + AMD graphics, Niri WM
#
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware
    ../../modules/software
    ../../modules/settings
  ];

  # Hostname
  networking.hostName = "flanker";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # amd_pstate: enable active mode for better CPU power management
  # (ACPI _CPC is missing in SBIOS but passive/active still improves scaling)
  boot.kernelParams = [ "amd_pstate=active" ];

  # Blacklist ucsi_ccg — causes i2c timeout errors on ASUS laptops with NVIDIA.
  # The USB-C controller fails to probe cleanly, blacklisting prevents the hang.
  boot.blacklistedKernelModules = [ "ucsi_ccg" ];

  # pre-shutdown.service is generated empty by NixOS when no shutdown scripts
  # are registered; give it a no-op so systemd doesn't log an error.
  systemd.services.pre-shutdown.serviceConfig.ExecStart = "${pkgs.coreutils}/bin/true";

  # NetworkManager-wait-online blocks boot for 4.5s — not needed on a desktop.
  systemd.services.NetworkManager-wait-online.enable = false;

  # Fulcrum's bulk storage — NFS share, mounted at /mnt/storage
  fileSystems."/mnt/storage" = {
    device  = "192.168.43.152:/mnt/storage";
    fsType  = "nfs";
    options = [ "nofail" "x-systemd.automount" "x-systemd.idle-timeout=600"
                "soft" "timeo=30" "retrans=2" ];
    # soft+timeo: fail fast (3s) when fulcrum is offline instead of hanging
  };

  # Games drive — 500GB XFS, mounted at /mnt/games
  fileSystems."/mnt/games" = {
    device  = "UUID=eb52e42f-65c7-4dee-8476-8087cb6e4dbe";
    fsType  = "xfs";
    options = [ "defaults" "nofail" ];
  };

  # Docker doesn't need to wait for network-online to start.
  systemd.services.docker.wants = [];
  systemd.services.docker.after = ["network.target"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable experimental features
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    xfsprogs   # XFS filesystem tools (mkfs.xfs, xfs_repair, etc.)
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # NFS mount — fulcrum's /mnt/storage
  fileSystems."/mnt/fulcrum" = {
    device  = "fulcrum:/mnt/storage";
    fsType  = "nfs";
    options = [ "nofail" "x-systemd.automount" "x-systemd.idle-timeout=600" "soft" "timeo=30" ];
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
