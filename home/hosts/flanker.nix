#
# ~/.nixos/home/hosts/flanker.nix
#
# Flanker-specific overrides (laptop, Hyprland-only)
#
{...}: {
  # Hyprland stack + WM-specific bits — flanker is the only host using these.
  # Fulcrum (Plasma) and tomcat (GNOME, separate repo) must not import them.
  imports = [
    ../modules/hyprland/hyprland.nix
    ../modules/rofi.nix       # launcher (Plasma uses KRunner)
    ../modules/fuzzel.nix     # secondary launcher (Wayland-native)
    ../modules/battery.nix    # UPower alerts + backup timer (laptop only)
    ../modules/matugen.nix    # wallpaper→color scheme sync (HyprPanel trigger)
  ];

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
  '';

  # Yandex Browser .desktop override moved to home/modules/yandex.nix
  # (DRI_PRIME=1 and --ozone-platform=wayland removed — they cause
  # transparent rendering under Hyprland with NVIDIA)
}
