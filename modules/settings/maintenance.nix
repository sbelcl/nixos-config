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
  # the WM and apps stay snappy. Builds take a bit longer, but the system
  # remains usable.
  systemd.services.nix-daemon.serviceConfig = {
    Nice = 19;
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
    CPUWeight = 20;
    IOWeight = 20;
  };
}
