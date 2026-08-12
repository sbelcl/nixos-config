#
# ~/.nixos/hosts/fulcrum/fulcrum.nix
#
# Gaming rig — SDDM + Plasma (Wayland), NVIDIA
#
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # nixpkgs gained its own services/misc/comfyui.nix, which declares the same
  # services.comfyui options as the comfyui-nix flake and made this host fail
  # to evaluate outright ("option ... is already declared"). Disable the
  # built-in one rather than migrating to it: it hardcodes
  # --base-directory=/var/lib/comfyui plus ProtectSystem=strict, and offers no
  # dataDir, gpuSupport or enableManager. Migrating would move the model
  # library off /mnt/storage onto the NVMe — the thing the block below exists
  # to avoid — and lose CUDA selection and ComfyUI Manager.
  #
  # Revisit if the upstream module grows a data directory option; at that point
  # the external input can be dropped entirely.
  disabledModules = [ "services/misc/comfyui.nix" ];

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

  # Override shared max-jobs (4) — fulcrum runs on phone hotspot at home,
  # so we serialize package builds to one at a time. Parallel downloads
  # swamp the hotspot DNS and cause 'Could not resolve host' failures.
  # cores=6 from maintenance.nix is unchanged.
  nix.settings.max-jobs = lib.mkForce 1;

  # ==========================================================================
  # Display Manager and Desktop Environments
  # ==========================================================================

  # SDDM (Wayland greeter) — Plasma is the only session offered on this rig.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # KDE Plasma 6 — the only desktop, best for gaming (VRR/HDR/tearing on NVIDIA)
  services.desktopManager.plasma6.enable = true;

  # Trim Plasma defaults we don't use.  akonadi/kdepim spawns a MariaDB-backed
  # PIM server and resource agents on login; the rest are apps superseded by
  # Nix-managed alternatives (mpv for audio, nix-env for software, etc.) or
  # things we never launch.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    akonadi
    kdepim-runtime
    elisa            # audio routed to mpv
    discover         # software management is via Nix
    khelpcenter
    krdp             # don't run an RDP server by default
    qrca
    kmag
    kmousetool
    kmouth
  ];

  # KDE Connect — phone integration (notifications, SMS, file send, clipboard).
  # programs.kdeconnect opens the discovery TCP/UDP ports 1714-1764 in the
  # firewall, which the package alone doesn't do.
  programs.kdeconnect.enable = true;

  # Keep the X server available for XWayland (X11 games/apps under Plasma) and
  # for SDDM. Xmonad has been removed.
  services.xserver.enable = true;

  # ==========================================================================
  # Gaming
  # ==========================================================================

  # Steam hardware support (controllers, etc.)
  hardware.steam-hardware.enable = true;

  # Steam "Gaming Mode" session (Deck-style) via gamescope — a dedicated SDDM
  # session that runs games in their own micro-compositor. Best path for HDR +
  # VRR on the ASUS VG34VQL3A: enter this session and enable HDR, or use the
  # per-game launch option:
  #   gamescope -f --hdr-enabled --adaptive-sync -- %command%
  programs.steam.gamescopeSession.enable = true;

  # Let gamescope raise its scheduling priority (CAP_SYS_NICE) for smoother frames.
  programs.gamescope.capSysNice = true;

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
    kdePackages.filelight       # disk usage treemap — /mnt/storage & /mnt/games
    kdePackages.isoimagewriter  # write Linux ISOs to USB
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

  # Remove comfyui from the boot critical path — without this override,
  # comfyui's WantedBy=multi-user.target + Requires=mnt-storage.mount forces
  # the storage fsck to run before graphical.target, adding ~12s to boot.
  # Instead, a timer starts it 30s after boot (storage mount is done by then).
  systemd.services.comfyui.wantedBy = lib.mkForce [];
  systemd.timers.comfyui = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      Unit = "comfyui.service";
    };
  };

  # Store Ollama models on bulk HDD to save NVMe space
  services.ollama.home = "/mnt/storage/ollama";

  # ==========================================================================
  # Bluetooth — fulcrum has no Bluetooth hardware.
  # The shared bluetooth.nix enables hardware.bluetooth, which installs a D-Bus
  # activation file for org.bluez.  Without hardware, bluetoothd exits
  # immediately, but D-Bus still waits service_start_timeout=25s for the name
  # to appear — so any Bluetooth client blocks 25s at login waiting for it.
  # Force the option off here so the activation file is never installed.
  # ==========================================================================
  hardware.bluetooth.enable = lib.mkForce false;
  hardware.bluetooth.powerOnBoot = lib.mkForce false;
  services.blueman.enable = lib.mkForce false;

  # ==========================================================================
  # System
  # ==========================================================================

  # DDC/CI monitor brightness control
  # ddcci-backlight creates a /sys/class/backlight device from DDC/CI
  # which lets standard tools (brightnessctl, etc.) control brightness
  hardware.i2c.enable = true;

  # "input" is fulcrum-only: the foot pedals are read straight from
  # /dev/input/*, which is root:input. It used to be granted to both hosts from
  # modules/settings/users.nix — flanker has no such hardware, and the
  # compositor does not need it (Hyprland gets input devices from logind, not
  # from the group), so the laptop no longer gets raw access to every keyboard.
  # ("video" is already granted by modules/settings/users.nix.)
  users.users.imnos.extraGroups = [ "i2c" "input" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
  boot.kernelModules = [ "ddcci" "ddcci-backlight" ];
  # DDC/CI backlight — create i2c client for the ASUS VG34VQL3A on the NVIDIA
  # display bus (i2c-4). NVIDIA GPU adapters don't auto-enumerate DDC clients,
  # so we create one at the standard DDC address (0x37).  The ddcci driver then
  # auto-binds to the new client and ddcci-backlight exposes
  # /sys/class/backlight/ddcci4 for brightness control.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="i2c-adapter", KERNEL=="i2c-4", \
      RUN+="${pkgs.bash}/bin/sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/%k/new_device'"
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
