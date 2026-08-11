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
    # SMB2 floor: SMB1/NT1 is removed from Windows 11 and disabled by default
    # on Windows 10, so allowing it buys no compatibility. Verified STANKO
    # negotiates fine with `smbclient -m SMB3`.
    client min protocol = SMB2
  '';


  # For network printer discovery (mDNS)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
