#
# ~/.nixos/modules/settings/printing.nix
#
{
  config,
  pkgs,
  ...
}: {
  services.printing.enable = true;
  services.printing.drivers = [pkgs.hplip]; # Replace or extend with your printer drivers

  # For network printer discovery (mDNS)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
