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
{ pkgs, lib, ... }: let
  # Nerd Font icons. Not in nixpkgs (only the neovim devicons are), so pinned
  # straight from upstream. Renders with the JetBrainsMono Nerd Font already
  # installed via fonts.nix.
  ranger-devicons = pkgs.fetchFromGitHub {
    owner = "alexanderjeurissen";
    repo = "ranger_devicons";
    rev = "1bcaff0366a9d345313dc5af14002cfdcddabb82";
    hash = "sha256-qvWqKVS4C5OO6bgETBlVDwcv4eamGlCUltjsBU3gAbA=";
  };

  # ranger opens files with its own launcher (rifle), which never consults
  # xdg-mime — it walks its packaged rule list and takes the first installed
  # match. For images that list knows viewnior/imv/pqiv/sxiv/feh/mirage/
  # ristretto/eog (none installed) but not loupe or qview, so it fell through
  # to gimp. Delegating to xdg-open keeps one source of truth: the defaults
  # declared in packages.nix.
  #
  # Unlike rc.conf, a user rifle.conf *replaces* the packaged one rather than
  # extending it, so the shipped rules are concatenated after ours. Built with
  # runCommand rather than builtins.readFile to avoid import-from-derivation.
  rifleLocal = pkgs.writeText "rifle-local.conf" ''
    mime ^image, has xdg-open, flag f = xdg-open "$@"
  '';
  rifleConf = pkgs.runCommand "rifle.conf" { } ''
    cat ${rifleLocal} ${pkgs.ranger}/share/doc/ranger/config/rifle.conf > $out
  '';
  # Image previews as coloured text, rendered inside the preview pane.
  #
  # The alternative was ueberzugpp, and it does not work here. Alacritty
  # implements no inline image protocol (no sixel, no kitty graphics), which
  # leaves ueberzug as ranger's only displayer — but its Wayland surface is a
  # real window as far as Hyprland is concerned: it drew *underneath* the
  # floating ranger and took keyboard focus on every selection change, so
  # moving to the next image meant refocusing ranger first. chafa renders into
  # the terminal itself, so there is no second window, nothing to steal focus,
  # and it uses the terminal palette.
  #
  # The packaged scope.sh classifies files with `file`, which is not installed
  # — without it every preview failed, images or not. Put the tools it needs on
  # PATH here rather than relying on the ambient environment.
  previewScript = pkgs.writeShellScript "ranger-scope" ''
    export PATH="${lib.makeBinPath [
      pkgs.file # mime classification — scope.sh does nothing without it
      pkgs.bat # syntax-highlighted text
      pkgs.imagemagick # thumbnails for formats chafa cannot read directly
      pkgs.poppler-utils # pdftotext, for PDF previews
    ]}:$PATH"
    case "$(${pkgs.file}/bin/file --mime-type -Lb "$1")" in
      image/*)
        # Clamp the pane size. ranger passes 0x0 whenever the preview column is
        # collapsed; chafa rejects that and emits nothing, and since a
        # pipeline's status is the *last* command's, the earlier version still
        # reported success. ranger cached an empty preview, kept the column
        # collapsed (collapse_preview), and so kept passing 0 — a blank pane
        # that sustained itself.
        w="''${2:-80}"; h="''${3:-24}"
        [ "$w" -ge 10 ] || w=80
        [ "$h" -ge 5 ]  || h=24

        # --colors 256 is required, not cosmetic: ranger parses ANSI itself and
        # its parser (gui/ansi.py) reads only xterm-256 codes, not chafa's
        # default truecolor. chafa also emits the cursor hide/show private
        # sequences (ESC[?25l/h) even with --animate off, which that parser
        # does not handle — strip them.
        img=$(${pkgs.chafa}/bin/chafa --format symbols --colors 256 \
                --size "''${w}x''${h}" --animate off -- "$1" 2>/dev/null \
              | ${pkgs.gnused}/bin/sed 's/\x1b\[?25[lh]//g')
        if [ -n "$img" ]; then
          printf '%s\n' "$img"
          exit 4
        fi
        ;;
    esac
    exec ${pkgs.ranger}/share/doc/ranger/config/scope.sh "$@"
  '';
in {
  home.packages = [ pkgs.chafa ];

  xdg.configFile."ranger/plugins/ranger_devicons".source = ranger-devicons;
  xdg.configFile."ranger/rifle.conf".source = rifleConf;

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

    # Use the preview script above. This override is essential: nixpkgs
    # patches ranger's packaged rc.conf to hardcode preview_script to the store
    # path of its *own* scope.sh, so a file at ~/.config/ranger/scope.sh is
    # never consulted — point straight at ours instead.
    set use_preview_script true
    set preview_script ${previewScript}

    # preview_images stays false on purpose: images are rendered as text by
    # scope.sh via chafa, so ranger must not try to drive an image displayer.
    set preview_images false
  '';
}
