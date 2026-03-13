#
# ~/.nixos/modules/settings/maintenance.nix
#
{ config, pkgs, ... }:

{
  # Automatic Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize Nix store (deduplicate files)
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Limit systemd journal size
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=7day
  '';
}
