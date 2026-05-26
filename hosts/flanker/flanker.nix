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
                "nfsvers=4" "soft" "timeo=30" "retrans=2" ];
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
    wine
    winetricks
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Lower swappiness — with 16GB RAM the kernel shouldn't be swapping under
  # browser load. Default 60 causes unnecessary swap pressure on memory spikes.
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Hyprland — the only WM on flanker (auto-login, no greeter)
  desktop.hyprland.enable = true;

  # Disable greetd — boot straight to TTY auto-login → Hyprland
  displayManager.greetd.enable = false;

  # Auto-login user on TTY1 (zsh profile starts Hyprland automatically)
  services.getty.autologinUser = "imnos";

  # GNOME Keyring — unlock on hyprlock auth (the primary login point)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
