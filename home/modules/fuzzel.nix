#
# ~/.nixos/home/modules/fuzzel.nix
#
# fuzzel — Wayland-native app launcher used in the Niri session.
# Colors follow the shared dark palette (0e0e0e bg, 7fc8ff accent).
#
{ pkgs, ... }: {
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=12
    lines=10
    width=42
    horizontal-pad=20
    vertical-pad=12
    inner-pad=8
    border-width=2
    border-radius=10
    icon-theme=Papirus-Dark
    icons-enabled=yes
    prompt=
    placeholder=Search apps...
    anchor=center
    match-mode=fuzzy
    show-actions=yes

    [colors]
    background=0e0e0ef5
    text=d8d8d8ff
    prompt=7fc8ffff
    placeholder=888888aa
    input=ffffffff
    match=22d4e0ff
    selection=2a3d52ff
    selection-text=ffffffff
    selection-match=7fc8ffff
    border=7fc8ffcc
  '';
}
