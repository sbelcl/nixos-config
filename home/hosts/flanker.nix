#
# ~/.nixos/home/hosts/flanker.nix
#
# Flanker-specific overrides (laptop, Hyprland-only)
#
{
  lib,
  pkgs,
  ...
}: let
  # Graphical sudo password prompt. Non-TTY callers (Claude Code's Bash tool,
  # scripts spawned from keybinds, systemd user units) can't read a password
  # from a terminal, so sudo needs a helper that reads one and prints it to
  # stdout. Per sudo(8), SUDO_ASKPASS is used automatically when no terminal
  # is available, so plain `sudo` keeps working in Alacritty and grows a
  # fuzzel prompt everywhere else — no -A flag and no NOPASSWD rule needed.
  sudo-askpass = pkgs.writeShellScriptBin "sudo-askpass" ''
    exec ${pkgs.fuzzel}/bin/fuzzel --dmenu --password --prompt-only="''${1:-sudo password: }"
  '';
in {
  # Hyprland stack + WM-specific bits — flanker is the only host using these.
  # Fulcrum (Plasma) and tomcat (GNOME, separate repo) must not import them.
  imports = [
    ../modules/hyprland/hyprland.nix
    ../modules/rofi.nix              # launcher (Plasma uses KRunner)
    ../modules/fuzzel.nix            # secondary launcher (Wayland-native)
    ../modules/battery.nix           # UPower alerts + backup timer (laptop only)
    ../modules/matugen.nix           # wallpaper→color scheme sync (via wallpaper-next)
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

  home.packages = [
    sudo-askpass
    # Client for fulcrum's Sunshine host (hosts/fulcrum/fulcrum.nix). Flanker
    # only — fulcrum is the machine being streamed from.
    pkgs.moonlight-qt
  ];

  # Clear Plasma's ksshaskpass out of the environment — flanker doesn't run
  # Plasma, but if PATH ever picks up ksshaskpass (e.g. via a nix profile),
  # having SSH_ASKPASS set would break `git push`'s gh credential helper.
  home.sessionVariables = {
    GIT_ASKPASS = "";
    SSH_ASKPASS = "";
    # Unrelated to the two above: those are blanked so ksshaskpass can't
    # hijack git/ssh, whereas sudo has no working fallback without a TTY.
    SUDO_ASKPASS = "${sudo-askpass}/bin/sudo-askpass";
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
  # Pin aquamarine to the NVIDIA DRM node so it doesn't try to init a
  # secondary multi-GPU renderer on the (non-existent) AMD DRM node — that
  # failure loops on every frame, burns ~1.5 cores of CPU, and starves input
  # handling so keyboard key-release events get dropped.
  wayland.windowManager.hyprland.settings.env = [
    { _args = [ "AQ_DRM_DEVICES" "/dev/dri/card1" ]; }
  ];

  # Workspace 3 is work-specific — Thunderbird and Chrome are only on flanker.
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      name = "ws3-thunderbird";
      match = {
        class = "thunderbird";
        title = "r:^(?!Sestavi:)";
      };
      workspace = "3 silent";
    }
    {
      name = "thunderbird-compose";
      match = {
        class = "thunderbird";
        title = "Sestavi:";
      };
      float = true;
      center = 1;
    }
    {
      name = "ws3-chrome";
      match.class = "google-chrome";
      workspace = "3 silent";
    }

    # ── eSpremnica (Pošta Slovenije shipping labels — Wine/XWayland) ─────
    # Two top-level windows: the real app UI ("eSpremnica") and a shell
    # container ("eSpremnica-Pošta Slovenije") that stays blank post-login.
    {
      name = "ws3-espremnica";
      match.class = "espremnica\\.exe";
      workspace = "3 silent";
    }
    {
      name = "espremnica-main";
      match = {
        class = "espremnica\\.exe";
        title = "^eSpremnica$";
      };
      center = 1;
    }
    {
      name = "espremnica-login";
      match = {
        class = "espremnica\\.exe";
        title = "_frmLogin";
      };
      center = 1;
    }
    # Note: an earlier attempt moved `eSpremnica-Pošta Slovenije` windows to
    # (-9999,-9999). The app spawns 5-6 windows with that same title (only one
    # is visible); hiding them all made the app fail to render its login form
    # and main UI. Use the SUPER+H keybind to hide the leftover blank window
    # manually after logging in.
  ];

  # Lock screen immediately on Hyprland start — flanker uses auto-login (no
  # greeter), so hyprlock is the only authentication gate after boot.
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("hyprlock")
    end)
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
