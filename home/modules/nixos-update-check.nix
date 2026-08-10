#
# ~/.nixos/home/modules/nixos-update-check.nix
#
# Weekly check for pending NixOS + home-manager updates. Bumps flake inputs,
# builds without switching, and pops a desktop notification if the new build
# differs from the running system so you can decide when to `updsys`/`updhome`.
#
{ config, pkgs, ... }: let
  flakeDir = "${config.home.homeDirectory}/.nixos";

  updateScript = pkgs.writeShellApplication {
    name = "nixos-update-check";
    runtimeInputs = with pkgs; [ nix libnotify coreutils git ];
    text = ''
      set -uo pipefail
      cd "${flakeDir}"

      # Bump flake inputs (system + home). Silent on network errors — we still
      # want to compare against the current lock in case an earlier update ran.
      nix flake update                        || true
      ( cd home && nix flake update )         || true

      # stderr flows to journalctl; we only capture stdout (the store path).
      if ! sys_out=$(nix build --no-link --print-out-paths \
          ".#nixosConfigurations.flanker.config.system.build.toplevel"); then
        notify-send -a "NixOS Updates" -u critical -t 30000 \
          "System build failed" "See: journalctl --user -u nixos-update-check"
        exit 1
      fi
      if ! home_out=$(nix build --no-link --print-out-paths \
          "./home#homeConfigurations.\"imnos@flanker\".activationPackage"); then
        notify-send -a "NixOS Updates" -u critical -t 30000 \
          "Home build failed" "See: journalctl --user -u nixos-update-check"
        exit 1
      fi

      current_sys=$(readlink -f /run/current-system)
      current_home=$(readlink -f \
        "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager")

      msg=""
      [ "$sys_out"  != "$current_sys"  ] && msg="''${msg}System: run updsys\n"
      [ "$home_out" != "$current_home" ] && msg="''${msg}Home: run updhome"

      if [ -n "$msg" ]; then
        # HyprPanel treats `-t 0` as "don't show" (not "persistent"), so use
        # `-u critical` — persists until dismissed and stands out visually.
        notify-send -a "NixOS Updates" -u critical \
          "Updates available" "$(printf '%b' "$msg")"
      fi
    '';
  };
in {
  systemd.user.services.nixos-update-check = {
    Unit.Description = "Check for NixOS + home-manager updates";
    Service = {
      Type = "oneshot";
      ExecStart = "${updateScript}/bin/nixos-update-check";
    };
  };

  systemd.user.timers.nixos-update-check = {
    Unit.Description = "Weekly NixOS update check";
    Timer = {
      OnCalendar = "weekly";
      RandomizedDelaySec = "1h";
      Persistent = true;   # catch up if the laptop was suspended/off
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
