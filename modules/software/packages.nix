#
# ~/.nixos/modules/software/packages.nix
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ntfsprogs
    ntfs3g
    lm_sensors    # hardware temperature monitoring (sensors command)
    smartmontools # disk health (smartctl -a /dev/nvme0)
    pciutils      # lspci — list PCI devices (GPUs, NICs, etc.)
    usbutils      # lsusb — list USB devices
  ];

  # Enable lm_sensors kernel modules
  hardware.sensor.iio.enable = true;
}
