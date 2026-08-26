#
# ~/.nixos/modules/settings/maintenance.nix
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  # openldap 2.6.13 has a flaky syncreplication test (test017) that fails
  # consistently in the Nix sandbox due to timing issues. Skip tests until
  # nixpkgs ships a fixed version or a cached binary.
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
    })
  ];
  # Automatic Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Cap rebuild concurrency. Defaults (max-jobs=auto × cores=0) try to run
  # one build per core, each using every core — up to 24×24 = 576 concurrent
  # compiler processes on this box. CUDA-heavy builds (ollama, torch deps)
  # spawn dozens of nvcc/cicc/ptxas/cc1plus, each holding 200-700 MB. RAM
  # evaporates in minutes and the OOM killer cascades. 4×6 = 24 keeps the
  # CPU busy without exploding memory.
  nix.settings = {
    max-jobs = 4;
    cores = 6;
  };

  # Optimize Nix store (deduplicate files)
  nix.optimise = {
    automatic = true;
    dates = ["weekly"];
  };

  # Compressed RAM swap — swap that lives in RAM, compressed, instead of on
  # disk. Sized at half of physical RAM (8 GB on flanker's 16 GB). Typical
  # ~3:1 compression means holding that full costs roughly 3 GB of real RAM,
  # so the net gain is ~5 GB of headroom for some CPU time. Cheap next to
  # swapping to NVMe, and neither host has a disk swap partition at all.
  #
  # 50% is the zram-generator default: a larger device is counterproductive,
  # since the compressed pages are themselves unswappable RAM.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Firmware updates (UEFI, SSD, dock, Thunderbolt) via LVFS: `fwupdmgr
  # refresh && fwupdmgr update`. Nothing else in this config can update
  # firmware — it sits below the Nix store entirely.
  services.fwupd.enable = true;

  # `locate <name>` over an index instead of walking the tree. plocate rather
  # than mlocate: same interface, much faster, and it is the one nixpkgs
  # actively maintains. The updatedb timer runs daily and prunes the Nix
  # store, which would otherwise dominate the index.
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  # `nh os switch` / `nh home switch` — same rebuild, but with a progress
  # view and a diff of what actually changed between generations.
  #
  # clean.enable is deliberately off: it and nix.gc.automatic (above) both
  # install a GC timer, and the nh module asserts if both are on. The
  # existing nix.gc keeps its 30-day policy.
  programs.nh = {
    enable = true;
    flake = "/home/imnos/.nixos";
  };

  # Limit systemd journal size
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=7day
  '';

  # Keep the desktop responsive during rebuilds. nix-daemon runs at idle
  # CPU/IO priority — only uses cycles when nothing else wants them, so
  # the WM and apps stay snappy. MemoryHigh/MemoryMax push the kernel to
  # throttle the daemon's cgroup before any process gets OOM-killed.
  systemd.services.nix-daemon.serviceConfig = {
    Nice = lib.mkForce 19;
    IOSchedulingClass = lib.mkForce "idle";
    IOSchedulingPriority = lib.mkForce 7;
    CPUWeight = 20;
    IOWeight = 20;
    MemoryHigh = "20G";
    MemoryMax = "26G";
  };
}
