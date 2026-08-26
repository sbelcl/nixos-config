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

    # Virtual "print to PDF" printer. Installs a CUPS queue named `pdf`;
    # jobs sent to it land as PDFs in the directory below.
    cups-pdf = {
      enable = true;
      instances.pdf.settings = {
        Out = "\${HOME}/Dokumenti/PDF";
        # created files owned by the printing user, rw for them only
        UserUMask = "0077";
      };
    };
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
