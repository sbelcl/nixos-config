#
# ~/.nixos/home/modules/niri/ags.nix
#
{
  pkgs,
  lib,
  ...
}: let
  astalPkgs = with pkgs.astal; [
    apps
    battery
    network
    wireplumber
    mpris
    tray
  ];

  # AGS needs to find the GObject Introspection typelibs for all astal libraries
  typeLibPath = lib.makeSearchPath "lib/girepository-1.0" ([pkgs.ags] ++ astalPkgs);
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
      Environment = ["GI_TYPELIB_PATH=${typeLibPath}"];
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
