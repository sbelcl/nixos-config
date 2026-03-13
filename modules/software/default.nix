#
# ~/.nixos/modules/software/default.nix
#
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common.nix
    ./niri.nix
    ./thunar.nix
    ./steam.nix
    ./docker.nix
    ./packages.nix
  ];
}
