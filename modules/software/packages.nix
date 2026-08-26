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
    dnsutils      # dig, nslookup — DNS diagnostics
    dmidecode     # hardware details (RAM slots, BIOS version, etc.)
    nvme-cli      # NVMe drive health (nvme smart-log /dev/nvme0)
  ];

  # LocalSend — AirDrop-style file transfer over the LAN. Enabled through the
  # NixOS module rather than home.packages because receiving needs TCP/UDP
  # 53317 open, and the package alone doesn't touch the firewall.
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Enable lm_sensors kernel modules
  hardware.sensor.iio.enable = true;
}
