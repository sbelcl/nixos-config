#
# ~/.nixos/modules/settings/users.nix
#
{ config, pkgs, ... }:
{
  users.users.imnos = {
    isNormalUser = true;
    description = "imnos";
    extraGroups = [ 
      "networkmanager" 
      "wheel"
      "seat"
      "video"
      "audio"
      "input"
      "disk"
      "storage"
      "plugdev"
      "scanner"
      "lp"	 
      "docker"
    ];
  };
  
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
