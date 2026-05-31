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
}
