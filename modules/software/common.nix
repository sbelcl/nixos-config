#
# ~/.nixos/modules/software/common.nix
#
{ lib, ... }:
{
  # High-priority, explicit choices live here
  security.polkit.enable = true;
  services.dbus.enable = lib.mkDefault true;
}

