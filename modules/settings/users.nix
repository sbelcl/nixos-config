#
# ~/.nixos/modules/settings/users.nix
#
{
  config,
  pkgs,
  ...
}: {
  users.users.imnos = {
    isNormalUser = true;
    description = "imnos";
    # Keep this list to groups that exist and are actually needed. Hardware
    # groups belong in the host that has the hardware (e.g. "input" for a
    # device that needs raw evdev access), not here.
    #
    # Removed, and why:
    #   seat, storage, plugdev, scanner — these groups do not exist on NixOS
    #     here, so membership was silently ignored. `seat` was left over from
    #     seatd (dropped in b56c67f); storage/plugdev are Debian/Arch
    #     conventions; scanner only exists with hardware.sane.enable.
    #   disk — grants raw read/write on whole block devices (/dev/nvme*,
    #     /dev/sda), which bypasses filesystem permissions entirely. Nothing
    #     needed it: udiskie talks D-Bus to udisks2, which runs as root and
    #     authorises through polkit, and no polkit rule here consults a group.
    #
    # docker and libvirtd stay, but note both are effectively root-equivalent:
    # anyone in them can start a privileged container or VM.
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "lp"
      "docker"
      "libvirtd"
    ];
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
