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
      RestartSec = "10s";
    };
    # Stop retrying after 3 failures in 60 s — prevents crash-loop when
    # `yandex-disk setup` hasn't been run yet (missing 'dir' config).
    Unit.StartLimitIntervalSec = 60;
    Unit.StartLimitBurst = 3;
    Install.WantedBy = ["default.target"];
  };
}
