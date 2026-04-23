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
  xdg.desktopEntries.yandex-browser-beta = {
    name       = "Yandex Browser (beta)";
    genericName = "Web Browser";
    # DRI_PRIME=1      → use AMD iGPU (renderD129) — display is wired to AMD
    # --ozone-platform=wayland → native Wayland instead of XWayland (huge perf win)
    exec       = "env DRI_PRIME=1 yandex-browser-beta --ozone-platform=wayland %U";
    icon       = "yandex-browser-beta";
    categories = [ "Network" "WebBrowser" ];
    mimeType   = [
      "application/pdf" "application/rdf+xml" "application/rss+xml"
      "application/xhtml+xml" "application/xhtml_xml" "application/xml"
      "image/gif" "image/jpeg" "image/png" "image/webp"
      "text/html" "text/xml"
      "x-scheme-handler/http" "x-scheme-handler/https"
    ];
    startupNotify = true;
  };
}
