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

      # Fix .desktop file: remove DRI_PRIME=1 (conflicts with NVIDIA in
      # Hyprland) and --ozone-platform=wayland (NIXOS_OZONE_WL handles it)
      for f in $out/share/applications/yandex-browser*.desktop; do
        substituteInPlace "$f" \
          --replace-quiet "env DRI_PRIME=1 " "" \
          --replace-quiet " --ozone-platform=wayland" ""
      done
    '';
  });
in {
  # Yandex Browser — from dedicated flake (wrapGAppsHook3 fix)
  home.packages = [
    yandex-browser-patched
    pkgs.yandex-disk
  ];

  # Override .desktop file — remove DRI_PRIME=1 and --ozone-platform=wayland
  # which cause transparent rendering on NVIDIA under Hyprland.
  # NIXOS_OZONE_WL=1 (set system-wide) handles Wayland detection instead.
  xdg.desktopEntries.yandex-browser-beta = {
    name = "Yandex Browser (beta)";
    genericName = "Web Browser";
    exec = "yandex-browser-beta %U";
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
      ExecStart = "${pkgs.yandex-disk}/bin/yandex-disk start --no-daemon";
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
