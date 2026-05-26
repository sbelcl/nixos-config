#
# ~/.nixos/home/hosts/flanker.nix
#
# Flanker-specific overrides (laptop)
#
{...}: {
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
    windowrule {
        name = ws3-thunderbird
        match:class = thunderbird
        workspace = 3 silent
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
