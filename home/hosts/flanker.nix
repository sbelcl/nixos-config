#
# ~/.nixos/home/hosts/flanker.nix
#
# Flanker-specific overrides (laptop, Hyprland-only)
#
{lib, ...}: {
  # Hyprland stack + WM-specific bits — flanker is the only host using these.
  # Fulcrum (Plasma) and tomcat (GNOME, separate repo) must not import them.
  imports = [
    ../modules/hyprland/hyprland.nix
    ../modules/rofi.nix              # launcher (Plasma uses KRunner)
    ../modules/fuzzel.nix            # secondary launcher (Wayland-native)
    ../modules/battery.nix           # UPower alerts + backup timer (laptop only)
    ../modules/matugen.nix           # wallpaper→color scheme sync (HyprPanel trigger)
    ../modules/nixos-update-check.nix # weekly flake-update + build + notify
  ];

  # No desktop dir on flanker — Hyprland has no desktop containment, so
  # ~/Namizje was only ever an empty folder. null drops XDG_DESKTOP_DIR from
  # user-dirs.dirs entirely. Kept host-local: fulcrum runs Plasma, which does
  # render desktop icons, so it keeps $HOME/Namizje from the shared module.
  # Caveat: with the key absent, `xdg-user-dir DESKTOP` reports the spec
  # fallback $HOME/Desktop — so anything that writes a desktop shortcut would
  # resurrect an English ~/Desktop. ~/.wine/drive_c/users/imnos/Desktop used to
  # symlink to ~/Namizje; it's now a real dir inside the prefix so Wine
  # installers keep their .lnk files there instead.
  # mkForce: nullOr can't merge a null over the shared module's string value.
  xdg.userDirs.desktop = lib.mkForce null;

  # Clear Plasma's ksshaskpass out of the environment — flanker doesn't run
  # Plasma, but if PATH ever picks up ksshaskpass (e.g. via a nix profile),
  # having SSH_ASKPASS set would break `git push`'s gh credential helper.
  home.sessionVariables = {
    GIT_ASKPASS = "";
    SSH_ASKPASS = "";
  };
  systemd.user.sessionVariables = {
    GIT_ASKPASS = "";
    SSH_ASKPASS = "";
  };

  programs.zsh.shellAliases = {
    updsys = "sudo nixos-rebuild switch --flake ~/.nixos#flanker";
    updhome = "home-manager switch --flake ~/.nixos/home#imnos@flanker";
  };

  # Force Yandex Browser to render on the AMD iGPU (renderD129) instead of
  # NVIDIA dGPU (renderD128). The laptop display is wired to the AMD GPU, so
  # rendering on NVIDIA requires a cross-adapter blit every frame → jank.
  # DRI_PRIME=1 selects the second GPU (AMD Renoir) as the render device.
  # Workspace 3 is work-specific — Thunderbird and Chrome are only on flanker.
  # Lock screen immediately on Hyprland start — flanker uses auto-login (no
  # greeter), so hyprlock is the only authentication gate after boot.
  wayland.windowManager.hyprland.settings.exec-once = [ "hyprlock" ];

  wayland.windowManager.hyprland.extraConfig = ''
    # Pin aquamarine to the NVIDIA DRM node so it doesn't try to init a
    # secondary multi-GPU renderer on the (non-existent) AMD DRM node —
    # that failure loops on every frame, burns ~1.5 cores of CPU, and
    # starves input handling so keyboard key-release events get dropped.
    env = AQ_DRM_DEVICES, /dev/dri/card1

    windowrule {
        name = ws3-thunderbird
        match:class = thunderbird
        match:title = r:^(?!Sestavi:)
        workspace = 3 silent
    }

    windowrule {
        name = thunderbird-compose
        match:class = thunderbird
        match:title = Sestavi:
        float  = true
        center = 1
    }

    windowrule {
        name = ws3-chrome
        match:class = google-chrome
        workspace = 3 silent
    }

    # ── eSpremnica (Pošta Slovenije shipping labels — Wine/XWayland) ─────
    # Two top-level windows: the real app UI ("eSpremnica") and a shell
    # container ("eSpremnica-Pošta Slovenije") that stays blank post-login.
    windowrule {
        name = ws3-espremnica
        match:class = espremnica\.exe
        workspace = 3 silent
    }
    windowrule {
        name = espremnica-main
        match:class = espremnica\.exe
        match:title = ^eSpremnica$
        center = 1
    }
    windowrule {
        name = espremnica-login
        match:class = espremnica\.exe
        match:title = _frmLogin
        center = 1
    }
    # Note: an earlier attempt moved `eSpremnica-Pošta Slovenije` windows to
    # (-9999,-9999). The app spawns 5-6 windows with that same title (only one
    # is visible); hiding them all made the app fail to render its login form
    # and main UI. Use the SUPER+H keybind below to hide the leftover blank
    # window manually after logging in.
  '';

  # Yandex Browser .desktop override moved to home/modules/yandex.nix
  # (DRI_PRIME=1 and --ozone-platform=wayland removed — they cause
  # transparent rendering under Hyprland with NVIDIA)

  # eSpremnica (Pošta Slovenije shipping labels, Wine). Appears in rofi
  # (drun mode) and fuzzel.
  xdg.desktopEntries.espremnica = {
    name          = "eSpremnica";
    genericName   = "Pošta Slovenije shipping labels";
    exec          = "wine /home/imnos/.wine/drive_c/eSpremnica/eSpremnica.exe";
    icon          = "wine";
    categories    = [ "Office" "Network" ];
    terminal      = false;
    startupNotify = true;
  };
}
