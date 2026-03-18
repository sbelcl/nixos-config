#
# ~/.nixos/modules/software/packages.nix
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ntfsprogs
    ntfs3g
    lm_sensors    # hardware temperature monitoring (sensors command)
    smartmontools # disk health (smartctl -a /dev/nvme0)
  ];

  # Enable lm_sensors kernel modules
  hardware.sensor.iio.enable = true;
}
