#
# ~/.nixos/home/modules/niri/ags.nix
#
{pkgs, ...}: let
  astalPkgs = with pkgs.astal; [
    apps
    battery
    network
    wireplumber
    mpris
    tray
  ];
  # Collect typelib dirs from all relevant packages using their Nix store paths
  giDirs = pkgs.lib.concatStringsSep ":" [
    "%h/.local/state/nix/profiles/home-manager/home-path/lib/girepository-1.0"
    "${pkgs.networkmanager}/lib/girepository-1.0"
    "/run/current-system/sw/lib/girepository-1.0"
  ];
in {
  home.packages = [pkgs.ags] ++ astalPkgs;

  xdg.configFile = {
    "ags/app.tsx".source = ./ags/app.tsx;
    "ags/style.css".source = ./ags/style.css;
  };

  systemd.user.services.ags = {
    Unit = {
      Description = "AGS desktop shell";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.ags}/bin/ags run";
      Environment = [
        "GI_TYPELIB_PATH=${giDirs}"
        "XDG_DATA_DIRS=${pkgs.adwaita-icon-theme}/share:/run/current-system/sw/share:%h/.local/share"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
