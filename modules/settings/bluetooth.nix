#
# ~/.nixos/modules/settings/bluetooth.nix
#
{
  config,
  pkgs,
  ...
}: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Bluetooth GUI tray
  services.blueman.enable = true;
}
