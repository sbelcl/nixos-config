#
# ~/.nixos/home/modules/hyprland/screenshot.nix
#
# The capture stack behind the Print keys. The plain grabs are one-liners and
# live in binds.nix as their own commands; these two need a pipeline, so they
# are scripts:
#
#   SHIFT + Print         region → satty → clipboard or file
#   SUPER + CTRL + Print  region → tesseract → clipboard
#   ALT + Print           region → mp4        (toggle)
#   SUPER + ALT + Print   monitor → mp4       (toggle)
#
# Screenshots are written to ~/Slike/Screenshots, which already existed;
# recordings to ~/Videi/Screencasts, resolved through xdg-user-dir rather than
# hardcoded, because that directory name is localised.
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

    # satty names the file but will not create the directory.
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/Slike/Screenshots"

    # Everything else is in ~/.config/satty/config.toml below, so a bare
    # `satty --filename shot.png` from a shell behaves like the keybind.
    ${pkgs.grim}/bin/grim -g "$region" - | ${pkgs.satty}/bin/satty --filename -
  '';

  # Screen recording — the video half of the Print family, and a toggle rather
  # than a hold: the second press stops whichever mode started it.
  #
  # The toggle goes through a pidfile rather than pkill. The process name the
  # kernel keeps is truncated to 15 characters — "gpu-screen-reco" — so
  # `pkill -x gpu-screen-recorder` matches nothing and says so, and matching
  # the short name instead would be a guess about where the truncation lands.
  #
  # Stopping is SIGINT, which is how gpu-screen-recorder is asked to finalise
  # the container. Anything harder leaves an mp4 with no moov atom, i.e. an
  # unplayable file with the recording inside it.
  #
  # gpu-screen-recorder is called by bare name on purpose. The NixOS module
  # (hosts/flanker/flanker.nix) puts a setcap wrapper on PATH, and that is the
  # one that records without opening a portal dialog; a ''${pkgs...} store path
  # would bypass the wrapper and prompt every time.
  screen-record = pkgs.writeShellScriptBin "screen-record" ''
    set -euo pipefail

    pidfile="''${XDG_RUNTIME_DIR:-/tmp}/screen-record.pid"

    # Second press: stop the running recorder and let the first invocation —
    # still sitting in `wait` below — do the notifying.
    if [ -e "$pidfile" ] && ${pkgs.coreutils}/bin/kill -0 "$(<"$pidfile")" 2>/dev/null; then
      ${pkgs.coreutils}/bin/kill -INT "$(<"$pidfile")"
      exit 0
    fi

    dir="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir VIDEOS)/Screencasts"
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    out="$dir/$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S).mp4"

    case "''${1:-monitor}" in
      region)
        # slurp's default output is "X,Y WxH"; -region wants "WxH+X+Y".
        # Cancelling the selection exits quietly, as the other scripts do.
        region=$(${pkgs.slurp}/bin/slurp -f "%wx%h+%x+%y") || exit 0
        set -- -w region -region "$region"
        ;;
      *)
        # The monitor Hyprland says has focus. Not `-w focused`, which is a
        # different feature — it follows focus between monitors and then
        # demands an explicit -s WxH for the output size, since that size can
        # no longer be read off one monitor.
        monitor=$(${pkgs.hyprland}/bin/hyprctl monitors -j \
          | ${pkgs.jq}/bin/jq -r 'map(select(.focused)) | .[0].name // empty')
        set -- -w "''${monitor:-screen}"
        ;;
    esac

    ${pkgs.libnotify}/bin/notify-send -a Recording -t 2000 \
      "Recording started" "Press the same key again to stop"

    # -a default_output is desktop sound. Add default_input as a second -a for
    # the microphone; gpu-screen-recorder takes one flag per source.
    gpu-screen-recorder "$@" -f 60 -a default_output -o "$out" &
    pid=$!
    echo "$pid" > "$pidfile"
    # SIGINT is a normal stop here, so a non-zero status is not a failure.
    wait "$pid" || true
    ${pkgs.coreutils}/bin/rm -f "$pidfile"

    ${pkgs.wl-clipboard}/bin/wl-copy "$out"
    ${pkgs.libnotify}/bin/notify-send -a Recording -t 5000 \
      "Recording saved" "$out (path copied)"
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
  # satty's behaviour, in the file it looks for on its own rather than on the
  # command line — it logged "config file not found" on every launch, and a
  # config makes the keybind and a hand-run `satty` behave identically.
  #
  # The palette is deliberately *not* wallpaper-derived, unlike everything
  # matugen touches. These are annotation ink: they have to stay legible on
  # top of whatever was on screen, which is not related to what the desktop
  # looks like. Red through blue, fully opaque, in the order the 1-9 keys
  # select them.
  sattyConfig = ''
    [general]
    initial-tool = "arrow"
    copy-command = "${pkgs.wl-clipboard}/bin/wl-copy"
    # Close after any save action, so the key behaves like a screenshot tool
    # rather than leaving an editor behind.
    early-exit = ["all"]
    actions-on-enter = ["save-to-clipboard"]
    # Only written when you ask for it (Ctrl+S); Ctrl+C or Enter copies.
    output-filename = "~/Slike/Screenshots/%Y-%m-%d_%H-%M-%S.png"
    default-round-caps = true
    primary-highlighter = "block"

    [font]
    family = "JetBrainsMono Nerd Font"
    style = "Regular"

    [color-palette]
    palette = [
      "#ff3b30ff",
      "#ff9500ff",
      "#ffcc00ff",
      "#34c759ff",
      "#32ade6ff",
      "#ffffffff",
      "#000000ff",
    ]
  '';
in {
  xdg.configFile."satty/config.toml".text = sattyConfig;

  home.packages = [
    screenshot-annotate
    ocr-region
    screen-record
    # On PATH in its own right: `satty --filename shot.png` reopens an old
    # capture for another pass.
    pkgs.satty
  ];
}
