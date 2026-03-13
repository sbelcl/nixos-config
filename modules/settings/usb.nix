#
# ~/.nixos/modules/settings/usb.nix
#
{
  config,
  pkgs,
  ...
}: {
  services.devmon.enable = true;
}
