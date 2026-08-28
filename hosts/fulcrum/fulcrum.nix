#
# ~/.nixos/hosts/fulcrum/fulcrum.nix
#
# Gaming rig — Hyprland (no greeter, TTY1 auto-login), NVIDIA, LUKS root
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

  # ==========================================================================
  # DNS — keep the hotspot's resolver out of it
  # ==========================================================================
  #
  # This machine lives permanently behind the phone hotspot, whose DHCP hands
  # out 192.168.43.1 as the nameserver. That resolver stops answering fairly
  # regularly (dig against it times out while the gateway still pings and
  # 1.1.1.1 answers fine), and while it is in that state every lookup on the
  # box dies -- which is what broke `nixos-rebuild` with a screenful of
  # "Could not resolve host: cache.nixos.org".
  #
  # modules/settings/networking.nix already intends to prevent this, via
  # networkmanager.connectionConfig ipv4/ipv6.ignore-auto-dns. It does not
  # work: those are *defaults for unset properties*, and the saved profile
  # still reports `ipv4.ignore-auto-dns: no`, so NM keeps handing the hotspot
  # resolver to systemd-resolved as a per-link server. Link DNS outranks the
  # global Quad9 list, so the good servers below never get consulted.
  #
  # dns = "none" takes NetworkManager out of DNS entirely, so resolved falls
  # back on its own global configuration -- Quad9, with proper #dns.quad9.net
  # names for TLS certificate validation.
  #
  # mkForce because the resolved module itself sets this to "systemd-resolved"
  # (nixos/modules/system/boot/resolved.nix) -- that wiring is precisely what
  # carries the per-link DHCP servers across, so overriding it is the point.
  networking.networkmanager.dns = lib.mkForce "none";

  # With the hotspot resolver gone, pin resolution to Quad9 over authenticated
  # TLS: "opportunistic" would still silently fall back to cleartext 53 against
  # whatever a network hands us. Verified 9.9.9.9:853 and 1.1.1.1:853 both
  # accept connections from here before turning this on.
  #
  # These two options are a pair, and the ordering matters if anyone unpicks
  # them later: strict DoT *without* dns = "none" is worse than neither. NM
  # would still push 192.168.43.1 onto the link, resolved would try DoT to a
  # phone that does not speak it, and strict mode forbids the fallback -- so
  # the machine would have no name resolution at all.
  #
  # Host-scoped deliberately. Strict DoT means no DNS whatsoever on a network
  # that blocks 853; fine for a desktop that never leaves this hotspot, wrong
  # for flanker, which moves between networks it does not control.
  services.resolved.settings.Resolve.DNSOverTLS = lib.mkForce "true";

  # Local DNSSEC validation off, delegated to Quad9 over the authenticated
  # channel above.
  #
  # Not a shrug at security -- resolved's own validation is what was breaking
  # here. Over this hotspot it intermittently fails to assemble the chain and
  # answers "DNSSEC validation failed: no-signature", including for zones that
  # are not signed at all (nixos.org has no DS record at its parent, so there
  # is nothing to validate). The failure is intermittent: the same name
  # resolves on one query and SERVFAILs on the next.
  #
  # That SERVFAIL is what actually broke `nixos-rebuild`, and it is worth
  # knowing why the symptom is so confusing. nsswitch.conf here reads
  #
  #     hosts: ... resolve [!UNAVAIL=return] files myhostname dns
  #
  # so a SERVFAIL from resolved is a *definitive* answer to glibc and the
  # trailing `dns` fallback is never consulted. Meanwhile `resolvectl query`
  # goes over D-Bus and can look fine at that same moment -- so the box appears
  # to have working DNS while every getaddrinfo() caller, nix included, fails.
  # Test with `getent ahosts`, not `resolvectl`, when judging this.
  #
  # 9.9.9.9 is a validating resolver and returns SERVFAIL for genuinely bogus
  # answers, so the check still happens; it happens there rather than here,
  # and DNSOverTLS = "true" is what makes trusting that answer reasonable.
  # These two settings are a pair in that direction too: do not turn this off
  # while leaving DoT opportunistic.
  services.resolved.settings.Resolve.DNSSEC = lib.mkForce "false";

  # NetworkManager-wait-online sat on the critical path for 37s of a 2m14s
  # boot: graphical.target -> multi-user.target -> docker.service ->
  # network-online.target -> here. Nothing on this box needs the network up
  # before the session starts. flanker has dropped this for the same reason
  # (its delay was only 4.5s -- this hotspot is far slower to settle).
  systemd.services.NetworkManager-wait-online.enable = false;

  # Socket-activate docker rather than starting it at boot; it is what pulls
  # network-online.target onto the critical path above. First `docker` command
  # of a session takes ~2s, everything after is unchanged. Also flanker's.
  virtualisation.docker.enableOnBoot = false;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ==========================================================================
  # LUKS unlock — TPM2, no passphrase at boot
  # ==========================================================================

  # The scripted initrd cannot talk to a TPM; systemd-cryptsetup in a systemd
  # initrd is what implements tpm2-device. This is the prerequisite for the
  # option below, not an independent preference.
  boot.initrd.systemd.enable = true;

  # Ask the TPM to release the key at boot. The device itself is declared in
  # hardware/hardware-configuration.nix — hardware there, policy here — and the
  # two attrsets merge.
  #
  # Safe before enrollment: with no TPM2 keyslot present this fails and falls
  # back to the passphrase prompt, so it can land in the same rebuild as the
  # Hyprland migration and be enrolled afterwards.
  #
  # Enrolled once, by hand, against PCRs 0+2+7 (firmware, option ROMs, secure
  # boot state):
  #
  #   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 \
  #     /dev/nvme0n1p2
  #
  # That ADDS a keyslot; the passphrase stays valid and is the recovery path.
  # Re-enroll after anything that changes those measurements — a BIOS update
  # moves PCR 0.
  #
  # Known limit, accepted deliberately: Secure Boot is disabled on this box, so
  # PCR 7 attests very little, and 0+2+7 measures neither kernel nor initrd.
  # /boot is unencrypted FAT, so someone with physical access could alter the
  # initrd and the TPM would still hand over the key. Data at rest is still
  # protected — a drive pulled from the machine, or a boot from other media,
  # will not unseal. Closing the rest means Secure Boot + lanzaboote, at which
  # point PCR 7 becomes load-bearing.
  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];

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
  # Desktop — Hyprland (migrated off SDDM + Plasma 6)
  # ==========================================================================

  # Hyprland is now the only session here, matching flanker. There is no
  # greeter: getty auto-logs in on TTY1, zsh execs start-hyprland (see
  # home/modules/users/imnos.nix + modules/software/hyprland.nix), and
  # hyprlock is the authentication gate.
  desktop.hyprland.enable = true;

  # NixOS applies this to tty1 only — tty2–tty6 still require a login, which
  # is the way back in if the compositor fails to start.
  services.getty.autologinUser = "imnos";

  # GNOME Keyring, unlocked by the hyprlock auth that replaces the greeter.
  # Plasma's kwallet went with plasma6, so without this nothing holds secrets
  # for the session.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;

  # KDE Connect — phone integration (notifications, SMS, file send, clipboard).
  # programs.kdeconnect opens the discovery TCP/UDP ports 1714-1764 in the
  # firewall, which the package alone doesn't do. Kept without Plasma: the
  # daemon is standalone, but its tray icon now needs kdeconnect-indicator
  # running against Wayle's systray rather than Plasma's applet.
  programs.kdeconnect.enable = true;

  # services.xserver.enable is gone with SDDM. XWayland is unaffected — it
  # comes from programs.hyprland (xwayland.enable defaults true), not from
  # the X server module, so X11 games and Wine keep working.

  # ==========================================================================
  # Gaming
  # ==========================================================================

  # Steam hardware support (controllers, etc.)
  hardware.steam-hardware.enable = true;

  # Steam "Gaming Mode" session (Deck-style) via gamescope — best path for
  # HDR + VRR on the ASUS VG34VQL3A.
  #
  # Kept enabled after the Plasma/SDDM removal, which costs less than it
  # looks: nixos/modules/programs/steam.nix installs `steam-gamescope` into
  # environment.systemPackages whenever this is on, and registers the
  # wayland-session .desktop with the display manager *separately*. With no
  # display manager the session entry has nothing to appear in, but the
  # launcher command survives — so Gaming Mode is now `steam-gamescope` from
  # rofi or a keybind instead of a greeter entry.
  #
  # Per-game alternative, unchanged:
  #   gamescope -f --hdr-enabled --adaptive-sync -- %command%
  programs.steam.gamescopeSession.enable = true;

  # Let gamescope raise its scheduling priority (CAP_SYS_NICE) for smoother frames.
  programs.gamescope.capSysNice = true;

  # Sunshine — stream this machine's screen to Moonlight on flanker over the
  # LAN. Steam Remote Play (enabled above) only streams Steam games; Sunshine
  # streams the whole desktop, so emulators, launchers and non-Steam titles
  # work too, and it uses NVENC on the 3080 Ti rather than a CPU encoder.
  #
  # capSysAdmin is required for KMS capture: without it Sunshine can only
  # capture through a portal and silently produces a black stream under
  # Plasma/Wayland.
  #
  # Pairing is a one-time step — open https://localhost:47990 here, then enter
  # the PIN Moonlight shows on flanker.
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;
  };

  # gpu-screen-recorder — NVENC capture with a replay buffer, so the last N
  # seconds can be saved after something happens rather than recording the
  # whole session. OBS (below) stays for planned/edited recordings.
  #
  # The module exists (rather than just the package) because promptless
  # capture needs setcap on the binary; installing the package alone makes
  # every recording pop a portal dialog.
  programs.gpu-screen-recorder.enable = true;

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
    kdePackages.filelight       # disk usage treemap — /mnt/storage
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

  # No /mnt/games on fulcrum any more. That was an XFS NVMe holding the Steam
  # library; the LUKS reinstall took over the same physical 931.5G drive, so
  # the filesystem is gone rather than unplugged and the UUID resolves to
  # nothing. The entry survived the reinstall because it lives here rather
  # than in hardware-configuration.nix, which is also why it was not caught
  # when that file was corrected.
  #
  # The Steam library is now the default one inside $HOME
  # (~/.local/share/Steam/steamapps) — the same physical disk it always was,
  # just no longer a separate filesystem. Nothing to declare for it.
  #
  # flanker still has a real /mnt/games; that one stays.

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

  # ollama.home is the unit's WorkingDirectory, so it has to exist before the
  # service starts; systemd cannot create it, and failed the whole unit at
  # namespace setup ("Failed to set up mount namespacing: /mnt/storage/ollama:
  # No such file or directory", 226/NAMESPACE) because the reinstalled /mnt
  # /storage no longer had it.
  #
  # Naming a user is what makes the tmpfiles rule below meaningful. Left at
  # null the module runs ollama under DynamicUser with a transient UID, and
  # there is no stable owner to give a directory outside /var/lib to. Setting
  # it creates the account (the module does that itself) and pins the owner.
  services.ollama.user = "ollama";
  services.ollama.group = "ollama";

  # d = create if missing, and do not touch anything already inside.
  # Z = recurse, resetting owner and mode on everything under the path.
  #
  # ComfyUI needs the recursive form because its data predates the reinstall
  # and the UIDs moved underneath it: the tree is owned by uid 991, which used
  # to be comfyui and now resolves to wpa_supplicant, while the service runs as
  # uid 998. At mode 0750 that is not a permissions nuisance but a hard stop --
  # comfyui.service could not even enter its own WorkingDirectory and died with
  # 200/CHDIR on every restart.
  #
  # Neither rule runs at boot, and that is the behaviour we want. /mnt/storage
  # is an x-systemd.automount, and tmpfiles refuses to walk through one rather
  # than triggering it:
  #
  #   Detected autofs mount point '/mnt/storage' during canonicalization
  #   Skipping /mnt/storage/comfyui
  #
  # So the recursive walk costs nothing per boot, and -- more usefully -- with
  # the drive unplugged these rules cannot create anything in the bare
  # mountpoint on the root filesystem, which is how stray files end up shadowed
  # under a mount. They apply during nixos-rebuild switch, when the filesystem
  # is already mounted, which is enough for a one-off ownership repair.
  #
  # Consequence worth knowing when applying this: activation restarts the
  # service and runs tmpfiles concurrently, so comfyui can fail 200/CHDIR once
  # more on the switch that fixes it and recover on its own Restart=. A failed
  # comfyui in that one switch is expected, not a reason to dig.
  systemd.tmpfiles.rules = [
    "d /mnt/storage/ollama 0750 ollama ollama -"
    "Z /mnt/storage/comfyui 0750 comfyui comfyui -"
  ];

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
