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

    # 🔹 DNS (override ISP if you want)
    nameservers = ["77.88.8.88" "77.88.8.2"];

    # 🔹 Firewall
    firewall = {
      enable = true;

      # Basic laptop rules
      allowPing = false; # optional, nice for diagnostics
      logRefusedConnections = true; # log dropped packets

      # Open only what you need
      allowedTCPPorts = [22]; # SSH (if you ever need it)
      allowedUDPPorts = [67 68 5353]; # DHCP client + mDNS for printers/lan
    };
  };

  # 🔹 Avahi for AirPrint, scanners, Chromecast, etc.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # 🔹 (Optional) systemd-resolved instead of resolvconf
  # services.resolved.enable = true;

  # 🔹 (Optional) Fail2ban if you expose SSH
  # services.fail2ban.enable = true;
}
