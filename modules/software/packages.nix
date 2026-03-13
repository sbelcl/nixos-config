#
# ~/.nixos/modules/software/packages.nix
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ntfsprogs
    ntfs3g
  ];
}
