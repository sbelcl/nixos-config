#
# ~/.nixos/modules/settings/printing.nix
#
{
  config,
  pkgs,
  ...
}: {
  services.printing = {
    enable = true;
    drivers = [
      pkgs.hplip      # general HP support
      pkgs.foo2zjs    # HP LaserJet 1010/1018/1020 (GDI printers)
    ];
  };

  # samba client for connecting to Windows shared printers (smb://)
  environment.systemPackages = [pkgs.samba];

  environment.etc."samba/smb.conf".text = ''
    [global]
    workgroup = WORKGROUP
    client min protocol = NT1
  '';


  # For network printer discovery (mDNS)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
