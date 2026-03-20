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

  # Suspend on lid close, hibernate after longer inactivity on battery
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandlePowerKey = "suspend";
    IdleAction = "suspend";
    IdleActionSec = "30min";
  };
}
