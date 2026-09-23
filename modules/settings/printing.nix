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

  # ── Queues ────────────────────────────────────────────────────────────────
  # Declared so they survive a reinstall — until now every queue lived only in
  # /etc/cups on the machine. The module never deletes a queue, so dropping an
  # entry here leaves the printer behind: remove it with `lpadmin -x <name>`.
  #
  # Only the LaserJet is listed, and the omissions are deliberate:
  #
  #   * The three HP_..._<serial> queues are created on the fly by
  #     cups-browsed from mDNS. Declaring them would fight the daemon that
  #     owns them.
  #   * `pdf` is already declared, by services.printing.cups-pdf above.
  #   * M125nw is driverless (IPP Everywhere), and `lpadmin -m everywhere`
  #     queries the printer to build its PPD. This runs in cups.service's
  #     postStart, so a rebuild anywhere that printer is unreachable would
  #     fail postStart and take cups down with it — verified: `-m everywhere`
  #     against an unreachable address errors and creates nothing, while the
  #     drv:/// PPD below succeeds even with a dead device URI. cups-browsed
  #     rediscovers that printer on its own anyway.
  hardware.printers.ensurePrinters = [
    {
      # A GDI printer shared from a Windows PC: rendering happens here
      # (hpcups, from hplip) and the result is shipped over SMB.
      #
      # printer-error-policy is the point of declaring it. CUPS defaults to
      # stop-printer, so a single job sent while STANKO is asleep disables the
      # whole queue until someone runs `cupsenable` by hand — which is exactly
      # what happened on 2026-09-23: NT_STATUS_HOST_UNREACHABLE at 08:27, then
      # four jobs stranded behind a disabled queue for over an hour.
      # retry-job leaves the job waiting for the host to come back instead.
      name = "HPLaserJet1010";
      deviceUri = "smb://STANKO/HPLaserjet1010";
      model = "drv:///hp/hpcups.drv/hp-laserjet_1010.ppd";
      description = "Servisni printer LaserJet 1010";
      location = "Stanko čaronalnik";
      ppdOptions."printer-error-policy" = "retry-job";
    }
  ];
  # No credentials here: the URI carries no username, so CUPS asks for them
  # (the queue has auth-info-required=username,password) and they stay out of
  # the store. lpadmin also warns that drv:/// PPDs are deprecated and will
  # stop working in a future CUPS — when that lands, this printer needs
  # another driver rather than another URI.

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
