#
# ~/.nixos/home/modules/hyprland/menu.nix
#
# The two ways to find a keybind without already knowing it:
#
#   SUPER+ALT+SPACE  hypr-menu       — searchable list of every runnable
#                                      action, which also runs it
#   SUPER+K          hypr-cheatsheet — the full bind list in a window
#
# Both are rendered from hyprland/binds.nix, the same list that produces the
# hl.bind() calls themselves, so neither can describe a key that isn't bound.
# That is the whole point: Omarchy's equivalent menu is hand-written bash
# beside its bindings file, and the two drift.
#
{ pkgs, ... }: let
  binds = import ./binds.nix;

  # display<TAB>command. The menu shows column one and looks the command back
  # up by exact match rather than by line number, so it does not care how
  # fuzzel reports the selection.
  menuData = pkgs.writeText "hypr-menu.tsv" binds.menuTsv;

  # Same markdown that docs/keybindings.md is generated from.
  cheatsheetDoc = pkgs.writeText "hypr-keybindings.md" binds.docsMarkdown;

  hypr-menu = pkgs.writeShellScriptBin "hypr-menu" ''
    set -euo pipefail

    # fuzzel exits non-zero when dismissed with Escape — leave quietly.
    choice=$(${pkgs.coreutils}/bin/cut -f1 ${menuData} \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "menu › " --lines 16 --width 64) || exit 0
    [ -n "$choice" ] || exit 0

    cmd=$(${pkgs.gawk}/bin/awk -F'\t' -v sel="$choice" '$1 == sel { print $2; exit }' ${menuData})
    [ -n "$cmd" ] || exit 0

    # Hand the command to Hyprland rather than running it here: exec_cmd is
    # what the keybind itself does, so a menu entry and its key produce an
    # identically parented process. It also detaches the child from this
    # script, which fuzzel's exit would otherwise take down.
    #
    # Spelled as Lua, not `hyprctl dispatch exec <cmd>`: with configType =
    # "lua", hyprctl wraps its argument as `return hl.dispatch(<arg>)` and
    # evaluates it, so the hyprlang spelling dies on a syntax error
    # ("')' expected near ..."). Same trap as `hyprctl keyword`, which the
    # layout toggle in qol.nix had to route through `hyprctl eval`.
    #
    # $cmd is interpolated inside double quotes and still cannot run here:
    # the shell does not rescan the result of a parameter expansion, so the
    # $(slurp) in the screenshot entry reaches Hyprland's own `sh -c` intact.
    exec ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.exec_cmd([[$cmd]])"
  '';

  # bat rather than less alone: the source is markdown, so headings and key
  # names get highlighted for free. --paging always because bat would
  # otherwise dump and exit, and the window would vanish with it; plain less
  # (no -F) so a short list still waits for `q`.
  hypr-cheatsheet = pkgs.writeShellScriptBin "hypr-cheatsheet" ''
    exec ${pkgs.alacritty}/bin/alacritty --class cheatsheet --title "Keybindings" \
      -e ${pkgs.bat}/bin/bat \
        --language md --style plain --paging always \
        --pager "${pkgs.less}/bin/less -R" \
        ${cheatsheetDoc}
  '';
in {
  home.packages = [ hypr-menu hypr-cheatsheet ];
}
