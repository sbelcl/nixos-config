#
# ~/.nixos/modules/settings/power.nix
#
{
  config,
  pkgs,
  ...
}: {
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Optional laptop-specific settings:
  # services.tlp.enable = true;
  # services.acpid.enable = true;
  # services.logind.lidSwitch = "suspend";
}
