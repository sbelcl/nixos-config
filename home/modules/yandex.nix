{
  config,
  pkgs,
  inputs,
  ...
}: let
  yandex-browser-beta = inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-beta;

  # Upstream flake bug: LD_LIBRARY_PATH references gstreamer-bin (no libs)
  # instead of the default output that has libgstreamer-1.0.so.
  # Wrap the browser to prepend the correct GStreamer library paths.
  gstLibPath = pkgs.lib.makeLibraryPath (with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

  yandex-browser-patched = yandex-browser-beta.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/yandex-browser-beta \
        --prefix LD_LIBRARY_PATH : "${gstLibPath}"

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
