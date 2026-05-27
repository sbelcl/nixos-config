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

  # Suspend on lid close; idle suspend handled by hypridle (Wayland-aware)
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandlePowerKey = "suspend";
  };
}
