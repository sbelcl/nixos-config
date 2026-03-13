#
# ~/.nixos/home/modules/polkit-agent.nix
#
{pkgs, ...}: {
  systemd.user.services.polkit-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
