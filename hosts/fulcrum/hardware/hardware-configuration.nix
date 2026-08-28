#
# ~/.nixos/hosts/fulcrum/hardware/hardware-configuration.nix
#
# Hand-corrected after the LUKS + btrfs reinstall (2026-08-28). The version
# this replaced was generated for the *previous* install and pointed at the
# other NVMe entirely: / on nvme1n1p2 (ext4), /boot on nvme1n1p1, swap on
# nvme1n1p3, and no LUKS device at all. That old disk is still fitted and its
# filesystems still exist, so a build from the stale file would have resolved
# those UUIDs successfully and produced a boot entry for the old system with
# no unlock step -- a silent wrong-system boot rather than a clean failure.
#
# Re-run `nixos-generate-config --show-hardware-config` after any disk change
# and diff it against this file.
#
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Root LUKS container on nvme0n1p2, opened as /dev/mapper/cryptroot. Every
  # btrfs mount below is a subvolume inside it.
  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/24ec0edc-ce6b-433f-a043-1018e00d28dd";

  fileSystems."/" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/nix" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
      neededForBoot = true;
    };

  fileSystems."/var/log" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@log" ];
      neededForBoot = true;
    };

  fileSystems."/home" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/.snapshots" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2A54-2DD1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  # No swap partition. The old install's swap was nvme1n1p3 on the other disk;
  # zram (modules/settings/maintenance.nix, 50% of RAM) is the swap now.
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
