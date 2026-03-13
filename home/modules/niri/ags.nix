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
      # Include typelibs from the home-manager profile (aggregates all user packages)
      # and the system profile (for system packages like NetworkManager)
      Environment = [
        "GI_TYPELIB_PATH=%h/.nix-profile/lib/girepository-1.0:/run/current-system/sw/lib/girepository-1.0"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
