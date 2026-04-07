{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Yandex Browser — from dedicated flake (wrapGAppsHook3 fix)
  home.packages = [
    inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-beta
    pkgs.yandex-disk
  ];

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
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
