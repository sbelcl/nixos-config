#
# ~/.nixos/modules/settings/default.nix
#
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./env.nix
    ./locales.nix
    ./maintenance.nix
    ./networking.nix
    ./power.nix
    ./printing.nix
    ./sddm.nix
    ./usb.nix
    ./users.nix
  ];
}
