#
# ~/.nixos/home/modules/niri/ags.nix
#
{pkgs, ...}: {
  programs.ags = {
    enable = true;
    extraPackages = with pkgs.astal; [
      apps
      battery
      network
      wireplumber
      mpris
      tray
      notifd
    ];
  };

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
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
