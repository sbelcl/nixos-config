{
  config,
  pkgs,
  inputs,
  ...
}: let
  # Shared with webapps.nix — see yandex-flags.nix.
  flags = import ./yandex-flags.nix;

  # `gnome2 = { GConf = null; }` drops one buildInputs entry. nixpkgs removed
  # gnome2.GConf on 2026-07-23 and replaced the attribute with a `throw`, so
  # merely *evaluating* the package's buildInputs fails against any newer
  # nixpkgs — the whole home config stops evaluating, which is what the weekly
  # canary has been reporting. Overriding the argument replaces the attrset the
  # package receives, so the throwing attribute is never touched; a null in
  # buildInputs is filtered by stdenv.
  #
  # Nothing is lost: Chromium dropped GConf support years ago and no ELF in the
  # built package has a libgconf DT_NEEDED (checked on 26.6.1.1084) — it was
  # dead weight in the dependency list.
  #
  # This is a workaround for github:sbelcl/nix-yandex-browser, where the real
  # one-line fix belongs (drop `gnome2` from the argument list and from
  # buildInputs in package/default.nix). The same file's `xorg.libxkbfile` is
  # already emitting a deprecation warning — renamed to a top-level
  # `libxkbfile` — so it is the next thing to break there.
  yandex-browser-beta =
    inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-beta.override {
      gnome2 = { GConf = null; };
    };

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
  # --use-angle=gl used to be here as well. It was countering the flake's
  # own baked-in --use-angle=vulkan, and that flag is gone as of
  # nix-yandex-browser 5ebd7d2, so there is nothing left to counter.
  #
  # Measured on flanker (AMD Renoir iGPU, Hyprland) after the EGL fix in
  # b925cd6, with and without the flag: byte-for-byte the same outcome —
  # WEBGL: ANGLE (AMD, AMD Radeon Graphics (radeonsi renoir), OpenGL ES 3.2)
  # and video decoding in both. It buys nothing here.
  #
  # NOT verified on fulcrum, which is the NVIDIA machine the flag was
  # originally written for and cannot be tested from flanker. The original
  # symptom was a window that maps but renders nothing. If that returns,
  # put `--use-angle=gl` back on the exec line below — but check the GPU
  # actually initialises first, because the real cause of that symptom was
  # LD_LIBRARY_PATH entries missing their /lib suffix, which meant EGL
  # never loaded at all and no ANGLE backend could have worked:
  #   yandex-browser-beta 2>&1 | grep -i "dlopen native EGL"
  xdg.desktopEntries.yandex-browser-beta = {
    name = "Yandex Browser (beta)";
    genericName = "Web Browser";
    exec = "yandex-browser-beta ${flags} %U";
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
