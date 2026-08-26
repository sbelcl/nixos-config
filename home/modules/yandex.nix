{
  config,
  pkgs,
  inputs,
  ...
}: let
  yandex-browser-beta = inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-beta;

  # The GStreamer wrapper that used to live here is gone: it prepended the
  # plugin packages to LD_LIBRARY_PATH, which was the wrong variable —
  # GStreamer finds plugins through GST_PLUGIN_SYSTEM_PATH_1_0, never the
  # linker path — and the flake's own inner wrapper `--set` that variable
  # afterwards, overwriting anything set out here regardless.
  #
  # Both halves are fixed upstream as of nix-yandex-browser 5ebd7d2: the
  # plugin path now uses gstreamer.out (the bare attribute resolves to the
  # plugin-less "bin" output) and includes ugly and libav.
  yandex-browser-patched = yandex-browser-beta.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      # Fix .desktop file: strip DRI_PRIME=1 — it forces the AMD iGPU on
      # flanker's hybrid GPU setup, which conflicts with NVIDIA under
      # Hyprland. Leave --ozone-platform=wayland intact; Yandex's own
      # launcher only adds it on Alt/Astra Linux and NIXOS_OZONE_WL doesn't
      # apply here (proprietary .deb, not a NixOS-wrapped chromium).
      for f in $out/share/applications/yandex-browser*.desktop; do
        substituteInPlace "$f" \
          --replace-quiet "env DRI_PRIME=1 " ""
      done
    '';
  });
in {
  # Yandex Browser — from dedicated flake (wrapGAppsHook3 fix)
  home.packages = [
    yandex-browser-patched
    pkgs.yandex-disk
  ];

  # Override .desktop file — set the launch flags explicitly:
  #  --ozone-platform=wayland : Yandex's launcher only adds this on
  #    Alt/Astra Linux (hardcoded distro check); on NixOS we must pass it
  #    ourselves or Chromium falls back to X11/XWayland, which on NVIDIA
  #    proprietary renders transparently under Plasma.
  #  --use-angle=gl : Chromium 144+ (Yandex 26.6.x) defaults to
  #    --use-angle=vulkan via ANGLE, which is broken on the NVIDIA
  #    proprietary driver — the window appears but renders nothing.
  #    Forcing ANGLE's OpenGL backend keeps hardware accel (video decode,
  #    WebGL, canvas GPU) while avoiding the Vulkan crash path.
  xdg.desktopEntries.yandex-browser-beta = {
    name = "Yandex Browser (beta)";
    genericName = "Web Browser";
    exec = "yandex-browser-beta --ozone-platform=wayland --use-angle=gl %U";
    icon = "yandex-browser-beta";
    categories = ["Network" "WebBrowser"];
    mimeType = [
      "application/pdf" "application/rdf+xml" "application/rss+xml"
      "application/xhtml+xml" "application/xhtml_xml" "application/xml"
      "image/gif" "image/jpeg" "image/png" "image/webp"
      "text/html" "text/xml"
      "x-scheme-handler/http" "x-scheme-handler/https"
    ];
    startupNotify = true;
    terminal = false;
  };

  # Yandex Disk daemon — run `yandex-disk setup` once to authenticate
  systemd.user.services.yandex-disk = {
    Unit = {
      Description = "Yandex Disk cloud storage daemon";
      After       = ["network-online.target"];
      Wants       = ["network-online.target"];
    };
    Service = {
      ExecStart = "${pkgs.yandex-disk}/bin/yandex-disk start --no-daemon --config=%h/.config/yandex-disk/config.cfg --dir=%h/Yandex.Disk";
      Restart   = "on-failure";
      RestartSec = "10s";
    };
    # Stop retrying after 3 failures in 60 s — prevents crash-loop when
    # `yandex-disk setup` hasn't been run yet (missing 'dir' config).
    Unit.StartLimitIntervalSec = 60;
    Unit.StartLimitBurst = 3;
    Install.WantedBy = ["default.target"];
  };
}
