#
# ~/.nixos/modules/settings/networking.nix
#
{lib, ...}: {
  networking = {
    # Hostname is set per-host in hosts/<hostname>/<hostname>.nix

    # 🔹Enable DHCP on all interfaces or use explicitly
    useDHCP = lib.mkDefault true;
    # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

    # 🔹 Network manager (easy Wi-Fi / VPN handling)
    networkmanager.enable = true;

    # 🔹 IPv6 privacy: don’t leak MAC address in IP
    tempAddresses = "enabled";

    # Ignore DNS pushed by router via DHCP — use Quad9 DoT from resolved instead
    nameservers = [];
    networkmanager.connectionConfig = {
      "ipv4.ignore-auto-dns" = "true";
      "ipv6.ignore-auto-dns" = "true";
    };

    # 🔹 Firewall
    firewall = {
      enable = true;

      # Basic laptop rules
      allowPing = false; # optional, nice for diagnostics
      logRefusedConnections = true; # log dropped packets

      # No incoming SSH — outbound connections work without open ports
      allowedTCPPorts = [];
      allowedUDPPorts = [67 68 5353]; # DHCP client + mDNS for printers/lan
    };
  };

  # 🔹 Avahi for AirPrint, scanners, Chromecast, etc.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # DNS over TLS via systemd-resolved — encrypts queries, ISP can't see domains
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      Domains = ["~."];
      DNS = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
        "2620:fe::fe#dns.quad9.net"
      ];
    };
  };

  # 🔹 (Optional) Fail2ban if you expose SSH
  # services.fail2ban.enable = true;
}
