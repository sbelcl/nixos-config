#
# ~/.nixos/home/modules/fuzzel.nix
#
# fuzzel — Wayland-native app launcher used in the Niri session.
# Colors follow the Binary Red palette (1a0a0a bg, c45454 accent).
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
    background=1a0a0af5
    text=e8d5d5ff
    prompt=c45454ff
    placeholder=887070aa
    input=fff0f0ff
    match=d4797aff
    selection=3d1e1eff
    selection-text=fff0f0ff
    selection-match=c45454ff
    border=c45454cc
  '';
}
