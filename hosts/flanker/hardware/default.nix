{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
  ];
}
