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

  # Keyboard RGB (Aura). This is a TUF A15 FA506IU: one RGB zone, driven by
  # asus-wmi rather than the USB HID interface the ROG models use. The kernel
  # exposes it as two write-only, root-owned files next to the backlight —
  # /sys/class/leds/asus::kbd_backlight/{kbd_rgb_mode,kbd_rgb_state} — which is
  # exactly why the Fn brightness keys work while colour does nothing: the
  # brightness node is writable through logind, the colour nodes are not.
  #
  # asusd owns those nodes and takes commands over D-Bus, so `asusctl aura`
  # works unprivileged. The module also brings in the package, its udev rules
  # and its D-Bus policy; there is no user service any more (the option was
  # removed upstream as no longer required).
  services.asusd.enable = true;

  # The Aura key (Fn+Left) reaches the OS as a WMI event the kernel has no
  # keymap entry for: `asus_wmi: Unknown key code 0xb2`. That log line is the
  # only trace of it anywhere — there is no input event, so nothing for the
  # compositor to bind, and no ACPI netlink event either.
  #
  # hwdb is the usual answer and does not work here. KEYBOARD_KEY_b2 applies
  # cleanly (udevadm shows the property on the device) but the EVIOCSKEYCODE
  # behind it fails silently: asus-wmi keeps its keymap in a sparse_keymap,
  # whose setkeycode only *replaces* scancodes already in the table and cannot
  # add 0xb2. Verified by reading the device's key capability bitmap — 228
  # (KBDILLUMTOGGLE) never appears, while 229/230 (the Fn+Up/Down brightness
  # keys, which the kernel does map) are there. Adding the entry upstream, or
  # patching asus-nb-wmi, is the only way to make this a real keycode.
  #
  # So the log line is the event. dmesg --follow-new rather than journalctl:
  # no dependency on journald being up or on its output format, and it starts
  # at the end of the ring buffer instead of replaying it. Fn+Right sends
  # nothing at all — not even this — so it stays dead.
  systemd.services.aura-key = let
    watcher = pkgs.writeShellApplication {
      name = "aura-key-watch";
      runtimeInputs = with pkgs; [ util-linux asusctl ];
      text = ''
        dmesg --follow-new | while IFS= read -r line; do
          case "$line" in
            *"Unknown key code 0xb2"*)
              # asusd owns the LED; a failure here (daemon restarting, say)
              # must not take the watcher down with it.
              asusctl aura effect --next-mode || true
              ;;
          esac
        done
      '';
    };
  in {
    description = "Aura key (Fn+Left) — next keyboard lighting effect";
    wants = [ "asusd.service" ];
    after = [ "asusd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.getExe watcher;
      Restart = "always";
      RestartSec = 2;
    };
  };

  # ...but enabling the module is not enough to make it run, which is easy to
  # mistake for the hardware being unsupported. asusd.service is Type=dbus with
  # BusName=xyz.ljones.Asusd and ships no [Install] section, so nothing in the
  # module ever wants it, and the package installs only D-Bus *policy*
  # (share/dbus-1/system.d/asusd.conf) — no activation file under
  # system-services/, so the bus cannot start it on demand either. The unit
  # lands "linked" and inactive, and asusctl answers "asusd is not running".
  systemd.services.asusd.wantedBy = [ "multi-user.target" ];

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
