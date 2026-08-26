#
# ~/.nixos/home/modules/hyprland/hyprland.nix
#
{ ... }: {
  imports = [
    ./config.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpaper.nix
    ./wayle.nix
    ./services.nix
    ./qol.nix
    ./menu.nix
    ./screenshot.nix
  ];
}
