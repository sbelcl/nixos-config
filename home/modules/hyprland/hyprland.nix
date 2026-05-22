#
# ~/.nixos/home/modules/hyprland/hyprland.nix
#
{ ... }: {
  imports = [
    ./config.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpaper.nix
    ./hyprpanel.nix
    ./services.nix
  ];
}
