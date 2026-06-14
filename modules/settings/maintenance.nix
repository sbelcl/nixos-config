#
# ~/.nixos/modules/settings/maintenance.nix
#
{
  config,
  pkgs,
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
    Nice = 19;
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
    CPUWeight = 20;
    IOWeight = 20;
    MemoryHigh = "20G";
    MemoryMax = "26G";
  };
}
