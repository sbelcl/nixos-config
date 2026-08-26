#
# ~/.nixos/modules/software/nautilus.nix
#
# System-side bits for Nautilus. The file manager itself is a home-manager
# package (home/modules/nautilus.nix) — only this has to be here, because
# the extension is found through NAUTILUS_4_EXTENSION_DIR, a session
# variable, and comes with nautilus-python.
#
# Gives Nautilus an "Open in Terminal" context entry pointing at Alacritty.
# The module also writes the terminal into the system dconf profile with
# lockAll, which is why home/modules/nautilus.nix does not set that key.
#
{ ... }: {
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
}
