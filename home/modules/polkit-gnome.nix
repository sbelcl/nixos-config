#
# ~/.nixos/home/module/polkit-gnome.nnix
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Namesti GNOME polkit agent
  home.packages = [
    pkgs.polkit_gnome
  ];

  # User service, ki zažene polkit-gnome-authentication-agent-1
  systemd.user.services.polkit-gnome-agent = {
    Unit = {
      Description = "GNOME PolicyKit Authentication Agent";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
