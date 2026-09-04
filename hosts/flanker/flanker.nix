#
# ~/.nixos/hosts/flanker/flanker.nix
#
# Laptop with hybrid NVIDIA + AMD graphics — Hyprland only.
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
  networking.hostName = "flanker";

  # Local dev domains — point at containers on loopback (Docker/Podman stack).
  networking.extraHosts = ''
    127.0.0.1 mcp.test
    127.0.0.1 pma.test
    127.0.0.1 mail.test
    127.0.0.1 digitalnisvet.test
    127.0.0.1 prosnik.test
  '';

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # systemd-boot default is 5s — drop to 1s. Press space/arrow at boot to
  # interrupt and pick an older generation.
  boot.loader.timeout = 1;

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

  # Bulk storage on the desktop at 192.168.43.152 — NFS share, mounted at
  # /mnt/storage. That machine runs Arch and is not configured from this repo,
  # so the export lives there; nofail + automount means a rebuild here still
  # succeeds if it is offline or has stopped exporting.
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

  # Docker: socket-activate instead of starting at boot. First `docker` command
  # of the session takes ~2s; everything after is the same. Saves ~2.3s off boot.
  virtualisation.docker.enableOnBoot = false;

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

  # Auto-login user on TTY1 (zsh profile starts Hyprland automatically).
  # NixOS only applies this to tty1 — tty2–tty6 still require login.
  services.getty.autologinUser = "imnos";

  # Ollama is not needed on the laptop
  services.ollama.enable = lib.mkForce false;

  # GNOME Keyring — unlock on hyprlock auth (the primary login point)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;

  # Share one sudo authentication across processes for 15 minutes. sudo keys
  # its credential cache to the controlling TTY, falling back to parent PID
  # when there is none — so every non-TTY caller (Claude Code's Bash tool, each
  # invocation a fresh parent) re-prompts, even seconds apart. Pairs with the
  # fuzzel SUDO_ASKPASS helper in home/hosts/flanker.nix.
  #
  # Tradeoff: within the window any process running as imnos can use the grant,
  # not just the one that authenticated. Acceptable on a single-user laptop
  # where hyprlock is the auth gate; it is host-local for that reason.
  security.sudo.extraConfig = ''
    Defaults timestamp_type=global
    Defaults timestamp_timeout=15
  '';

  system.stateVersion = "25.05"; # Did you read the comment?
}
