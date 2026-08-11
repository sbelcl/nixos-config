#
# ~/.nixos/home/modules/ranger.nix
#
# ranger — TUI file manager. Opened with SUPER+R and popped up floating on
# USB mount (see hyprland/config.nix and hyprland/services.nix); the package
# itself lives in packages.nix.
#
# Colors: deliberately nothing here. ranger's default colorscheme uses ANSI
# colour *names* (blue, cyan, green, ...) rather than fixed 256-colour indices,
# so it renders with whatever palette the terminal has. Alacritty's palette is
# matugen-generated, so ranger already follows the wallpaper for free. Writing
# a matugen template for ranger would mean pinning numeric colour indices and
# would actually make it track the wallpaper *less* well.
#
{ pkgs, ... }: let
  # Nerd Font icons. Not in nixpkgs (only the neovim devicons are), so pinned
  # straight from upstream. Renders with the JetBrainsMono Nerd Font already
  # installed via fonts.nix.
  ranger-devicons = pkgs.fetchFromGitHub {
    owner = "alexanderjeurissen";
    repo = "ranger_devicons";
    rev = "1bcaff0366a9d345313dc5af14002cfdcddabb82";
    hash = "sha256-qvWqKVS4C5OO6bgETBlVDwcv4eamGlCUltjsBU3gAbA=";
  };
in {
  xdg.configFile."ranger/plugins/ranger_devicons".source = ranger-devicons;

  # ranger reads its packaged rc.conf first, then this one, so only the
  # deltas belong here.
  xdg.configFile."ranger/rc.conf".text = ''
    # Icons in the file listing (ranger_devicons plugin).
    default_linemode devicons

    # Show the size of directories' contents rather than the inode size.
    set automatically_count_files true

    # Preview the highlighted file in the right column.
    set preview_files true
    set preview_directories true

    # Use bat for syntax-highlighted previews when it is on PATH — it picks up
    # the same theme story as the rest of the terminal.
    set use_preview_script true
  '';
}
