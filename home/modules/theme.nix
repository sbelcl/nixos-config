#
# ~/.nixos/home/modules/theme.nix
#
# What the session's colours are derived from, and how they get re-derived.
# matugen.nix owns the templates; this owns the source, the mode, and the
# three ways they change:
#
#   SUPER+SHIFT+W  wallpaper-next  next wallpaper, colours follow it
#   SUPER+SHIFT+T  theme-set       pick the source: wallpaper or a named seed
#   SUPER+ALT+T    theme-mode      light / dark, on a key or on a timer
#
# All three funnel through theme-apply, which is the only thing that runs
# matugen. That is why wallpaper-next lives here rather than in rofi.nix,
# where it started: it needs the stored mode, and duplicating that logic in
# two modules is how the two drift.
#
# State is two one-line files under ~/.local/state/theme, because the source
# and mode have to survive a reboot and there is nowhere declarative to put
# something the user changes at runtime.
#
{ config, pkgs, lib, ... }: let
  notify = "${pkgs.libnotify}/bin/notify-send";
  stateDir = "${config.xdg.stateHome}/theme";

  # Switch to false to keep the light/dark timers out of the session.
  autoSwitch = true;
  lightAt = "07:30";
  darkAt = "19:30";

  # Named source colours. These are *seeds*, not ports: matugen derives a
  # whole Material scheme from one colour, so "Indigo" is in the key of
  # Tokyo Night rather than being its palette. Naming them after the themes
  # they are reminiscent of would be a promise the generator cannot keep.
  seeds = [
    { name = "Indigo"; hex = "#7aa2f7"; }
    { name = "Amber"; hex = "#d79921"; }
    { name = "Forest"; hex = "#a7c080"; }
    { name = "Ice"; hex = "#88c0d0"; }
    { name = "Mauve"; hex = "#c4a7e7"; }
    { name = "Graphite"; hex = "#8f8f8f"; }
  ];

  seedMenu = lib.concatMapStringsSep "\n" (s: "${s.name}\t${s.hex}") seeds;
  seedMenuFile = pkgs.writeText "theme-seeds.tsv" (seedMenu + "\n");

  # ── The one place matugen is invoked ──────────────────────────────────────
  # Reads the two state files and re-renders everything from them. Every
  # other script here writes state and then calls this.
  theme-apply = pkgs.writeShellScriptBin "theme-apply" ''
    set -uo pipefail
    ${pkgs.coreutils}/bin/mkdir -p ${stateDir}

    mode=$(${pkgs.coreutils}/bin/cat ${stateDir}/mode 2>/dev/null || echo dark)
    kind=image
    value="$HOME/.config/background"
    if [ -r ${stateDir}/source ]; then
      read -r kind value < ${stateDir}/source || true
    fi

    case "$kind" in
      color)
        ${pkgs.matugen}/bin/matugen -m "$mode" color hex "$value" || exit 1
        ;;
      *)
        # --prefer is mandatory from a keybind: matugen aborts rather than
        # pick between candidate source colours when it has no TTY to ask on.
        ${pkgs.matugen}/bin/matugen -m "$mode" image "$value" --prefer saturation || exit 1
        ;;
    esac

    # libadwaita reads this, and it is what makes Nautilus and every GTK 4
    # dialog follow the mode rather than just the colours.
    ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'" || true

    # Wayle picks which half of the matugen palette to use. wallpaper-next
    # may override this straight afterwards — see the note there.
    if [ "$mode" = light ]; then light=true; else light=false; fi
    ${pkgs.wayle}/bin/wayle config set styling.matugen-light "$light" >/dev/null 2>&1 || true
  '';

  # ── Mode ──────────────────────────────────────────────────────────────────
  theme-mode = pkgs.writeShellScriptBin "theme-mode" ''
    set -uo pipefail
    ${pkgs.coreutils}/bin/mkdir -p ${stateDir}

    current=$(${pkgs.coreutils}/bin/cat ${stateDir}/mode 2>/dev/null || echo dark)
    want="''${1:-toggle}"

    case "$want" in
      toggle) if [ "$current" = dark ]; then want=light; else want=dark; fi ;;
      light|dark) ;;
      *)
        ${notify} -u critical "Theme" "Usage: theme-mode light|dark|toggle"
        exit 1
        ;;
    esac

    printf '%s\n' "$want" > ${stateDir}/mode
    ${theme-apply}/bin/theme-apply
    ${notify} -u low "Theme" "$want mode"
  '';

  # ── Source ────────────────────────────────────────────────────────────────
  # fuzzel over the seeds above plus the wallpaper. Same display/lookup shape
  # as the action menu: show column one, resolve the value by exact match.
  theme-set = pkgs.writeShellScriptBin "theme-set" ''
    set -uo pipefail
    ${pkgs.coreutils}/bin/mkdir -p ${stateDir}

    choice=$( { echo "From wallpaper"; ${pkgs.coreutils}/bin/cut -f1 ${seedMenuFile}; } \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "theme › " --lines 8 --width 28) || exit 0
    [ -n "$choice" ] || exit 0

    if [ "$choice" = "From wallpaper" ]; then
      printf 'image %s\n' "$HOME/.config/background" > ${stateDir}/source
    else
      hex=$(${pkgs.gawk}/bin/awk -F'\t' -v s="$choice" '$1 == s { print $2; exit }' ${seedMenuFile})
      [ -n "$hex" ] || exit 0
      printf 'color %s\n' "$hex" > ${stateDir}/source
    fi

    ${theme-apply}/bin/theme-apply
    ${notify} -u low "Theme" "$choice"
  '';

  # ── Wallpaper ─────────────────────────────────────────────────────────────
  # Moved here from rofi.nix: the colours it triggers have to come out in the
  # stored mode, which only theme-apply knows.
  wallpaper-next = pkgs.writeShellScriptBin "wallpaper-next" ''
    set -u
    DIR="$HOME/Slike/Ozadja"
    BG="$HOME/.config/background"

    NEXT=$(${pkgs.findutils}/bin/find "$DIR" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      2>/dev/null | ${pkgs.coreutils}/bin/shuf -n1)
    if [ -z "$NEXT" ]; then
      ${notify} "wallpaper-next" "No images in $DIR" 2>/dev/null
      exit 1
    fi

    # ~/.config/background is the single source of truth: awww paints it,
    # hyprlock blurs it, and theme-apply reads it.
    # Copy rather than symlink — hyprpaper.nix requires a regular writable file.
    ${pkgs.coreutils}/bin/cp -f "$NEXT" "$BG"

    # awww, not hyprpaper — see hyprland/hyprpaper.nix for why. Wayle's
    # wallpaper engine drives the same daemon, so the two can coexist.
    ${pkgs.awww}/bin/awww img "$BG"

    # Changing the wallpaper also makes it the colour source again, so a
    # named seed does not silently outlive the picture it was chosen against.
    ${pkgs.coreutils}/bin/mkdir -p ${stateDir}
    printf 'image %s\n' "$BG" > ${stateDir}/source
    ${theme-apply}/bin/theme-apply

    # Last word on Wayle's polarity, overriding what theme-apply just set.
    # The bar is fully transparent (bar.background-opacity = 0), so its text
    # sits directly on the wallpaper: a bright picture leaves light text on
    # light pixels regardless of which mode the session is in. Readability
    # over consistency, deliberately.
    LUMA=$(${pkgs.imagemagick}/bin/magick "$BG" -resize '1x1!' -colorspace gray \
      -format "%[fx:int(255*u)]" info: 2>/dev/null || echo 0)
    if [ "$LUMA" -gt 128 ]; then LIGHT=true; else LIGHT=false; fi
    ${pkgs.wayle}/bin/wayle config set styling.matugen-light "$LIGHT" >/dev/null 2>&1 || true
  '';

  modeUnit = mode: at: {
    "theme-${mode}" = {
      Unit = {
        Description = "Switch the session to ${mode} colours";
        ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${theme-mode}/bin/theme-mode ${mode}";
      };
    };
  };

  modeTimer = mode: at: {
    "theme-${mode}" = {
      Unit.Description = "Switch the session to ${mode} colours at ${at}";
      Timer = {
        OnCalendar = "*-*-* ${at}:00";
        # Catch up after a suspend that spanned the switch, rather than
        # waiting until tomorrow.
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
in {
  home.packages = [ theme-apply theme-mode theme-set wallpaper-next ];

  systemd.user.services = lib.mkIf autoSwitch (
    (modeUnit "light" lightAt) // (modeUnit "dark" darkAt)
  );
  systemd.user.timers = lib.mkIf autoSwitch (
    (modeTimer "light" lightAt) // (modeTimer "dark" darkAt)
  );

  # Re-apply the stored source and mode after every `updhome`. Without this,
  # matugen.nix's own regeneration (which runs when a template changes) would
  # render in dark from the wallpaper and quietly undo a light session or a
  # named seed. Ordered after both the thing it corrects and the dconf write
  # it needs to win over.
  home.activation.themeReapply =
    lib.hm.dag.entryAfter [ "matugenRegen" "dconfSettings" ] ''
      if [ -r ${stateDir}/mode ] || [ -r ${stateDir}/source ]; then
        $DRY_RUN_CMD ${theme-apply}/bin/theme-apply || true
      fi
    '';
}
