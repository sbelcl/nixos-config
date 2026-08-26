#
# ~/.nixos/home/modules/hyprland/screenshot.nix
#
# The capture stack behind the Print keys. The plain grabs are one-liners and
# live in binds.nix as their own commands; these two need a pipeline, so they
# are scripts:
#
#   SHIFT + Print         region → satty → clipboard or file
#   SUPER + CTRL + Print  region → tesseract → clipboard
#
# Screenshots are written to ~/Slike/Screenshots, which already existed.
#
{ pkgs, ... }: let
  # Annotate before sending. grim hands the PNG to satty on stdin, and satty
  # writes nothing on its own: Ctrl+C (or Enter) copies, Ctrl+S saves to the
  # name below — --output-filename only *names* the target, it does not
  # imply saving. --early-exit=all closes the editor after either action, so
  # the key behaves like a screenshot tool instead of leaving a window
  # behind; drop it if you would rather keep annotating after a copy.
  #
  # --initial-tool=arrow because pointing at the thing you are talking about
  # is the common case; `crop`, `blur` and `text` are one word away.
  screenshot-annotate = pkgs.writeShellScriptBin "screenshot-annotate" ''
    set -euo pipefail

    # slurp exits non-zero when the selection is cancelled (Escape or a
    # zero-width drag) — leave silently, exactly as ocr-region does.
    region=$(${pkgs.slurp}/bin/slurp) || exit 0

    ${pkgs.coreutils}/bin/mkdir -p "$HOME/Slike/Screenshots"

    ${pkgs.grim}/bin/grim -g "$region" - \
      | ${pkgs.satty}/bin/satty --filename - \
          --output-filename "$HOME/Slike/Screenshots/%Y-%m-%d_%H-%M-%S.png" \
          --copy-command ${pkgs.wl-clipboard}/bin/wl-copy \
          --actions-on-enter save-to-clipboard \
          --early-exit=all \
          --initial-tool=arrow
  '';

  # Select a screen region, OCR it, put the text on the clipboard.
  #
  # slv+eng, in that order: tesseract weights the first language highest, and
  # the Slovenian model is the one that knows š/č/ž — running eng-only on
  # Slovenian text silently mangles them into s/c/z rather than failing. eng
  # follows because most of what gets grabbed off a screen is English UI text
  # or code. pkgs.tesseract ships every traineddata file, so neither needs
  # requesting separately.
  #
  # Writing grim's output to a file instead of piping it: tesseract seeks
  # its input, so it cannot read a pipe, and `tesseract - -` fails on stdin
  # that isn't a real file.
  ocr-region = pkgs.writeShellScriptBin "ocr-region" ''
    set -euo pipefail

    # slurp exits non-zero when the selection is cancelled (Escape or a
    # zero-width drag). Leave silently — a notification there would fire on
    # every mis-drag.
    region=$(${pkgs.slurp}/bin/slurp) || exit 0

    img=$(mktemp --suffix=.png)
    trap 'rm -f "$img"' EXIT
    ${pkgs.grim}/bin/grim -g "$region" "$img"

    # tesseract writes progress to stderr and exits non-zero on an empty
    # image; treat "no text" as a normal outcome, not a crash.
    text=$(${pkgs.tesseract}/bin/tesseract "$img" - -l slv+eng 2>/dev/null || true)

    # Strip surrounding whitespace: tesseract always appends newlines, and
    # pasting those into a chat box sends the message early. Escaped as
    # ''${ so Nix leaves the parameter expansion for bash instead of trying
    # to interpolate `text` at build time.
    shopt -s extglob
    text="''${text##+([[:space:]])}"
    text="''${text%%+([[:space:]])}"

    if [ -z "$text" ]; then
      ${pkgs.libnotify}/bin/notify-send -u normal "OCR" "No text found in selection"
      exit 0
    fi

    printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
    ${pkgs.libnotify}/bin/notify-send "Text extracted" "$(printf '%s' "$text" | head -c 120)"
  '';
in {
  home.packages = [
    screenshot-annotate
    ocr-region
    # On PATH in its own right: `satty --filename shot.png` reopens an old
    # capture for another pass.
    pkgs.satty
  ];
}
