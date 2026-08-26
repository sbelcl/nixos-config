#
# ~/.nixos/home/hosts/fulcrum.nix
#
# Fulcrum-specific home overrides (gaming rig, Plasma-only)
#
{ pkgs, config, lib, ... }: {
  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#fulcrum";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@fulcrum";
  };

  # Fulcrum-specific packages not in the shared home config
  home.packages = with pkgs; [
    vscode
  ];

  # Plasma rewrites these GTK config files on every session start (flipping
  # the icon theme, etc.), which turns HM's symlink into a real file and
  # then blocks the next updhome ("existing file in the way"). fonts.nix
  # already dictates the theme we want, so pre-delete any Plasma-touched
  # file before HM re-links.
  home.activation.stripPlasmaGtkRewrites =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f \
        "$HOME/.gtkrc-2.0" \
        "$HOME/.config/gtk-3.0/settings.ini" \
        "$HOME/.config/gtk-4.0/settings.ini" \
        "$HOME/.config/gtk-4.0/gtk.css"
    '';
}
