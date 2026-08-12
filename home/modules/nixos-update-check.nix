#
# ~/.nixos/home/modules/nixos-update-check.nix
#
# Weekly check for pending NixOS + home-manager updates. Resolves newer flake
# inputs in a throwaway copy of the tree, verifies every host still evaluates,
# builds this host, and notifies if an update is worth applying.
#
# Two deliberate properties, both learned the hard way:
#
#   * It never writes to ~/.nixos. The previous version ran `nix flake update`
#     in the real checkout, so a background timer rewrote both lock files and
#     left the tree dirty — silently changing what the next `updsys` would
#     build, with no record of when or why.
#
#   * It checks *every* host, not just this one. The previous version built
#     flanker only, which is how fulcrum sat un-rebuildable for two days after
#     nixpkgs grew its own services.comfyui and collided with the comfyui-nix
#     module: the canary was structurally incapable of seeing it.
#
{ config, pkgs, ... }: let
  flakeDir = "${config.home.homeDirectory}/.nixos";

  updateScript = pkgs.writeShellApplication {
    name = "nixos-update-check";
    runtimeInputs = with pkgs; [ nix libnotify coreutils git jq ];
    text = ''
      set -uo pipefail

      notify_fail() {
        notify-send -a "NixOS Updates" -u critical -t 30000 \
          "$1" "$2"$'\n'"See: journalctl --user -u nixos-update-check"
      }

      # Throwaway copy: flake updates land here and are discarded. .git is
      # dropped so nix treats it as a plain path flake — otherwise every
      # command warns about a dirty tree and only committed files are seen.
      tmp=$(mktemp -d) || exit 1
      trap 'rm -rf "$tmp"' EXIT
      cp -a "${flakeDir}/." "$tmp/" || exit 1
      rm -rf "$tmp/.git"
      cd "$tmp"

      # Resolve newer inputs. Network failures are tolerated: the checks below
      # are still worth running against the existing lock.
      nix flake update                 || true
      ( cd home && nix flake update )  || true

      this_host=$(uname -n)
      broken=""

      # Other hosts: evaluate only. That is enough to catch option collisions,
      # renamed attributes and type errors — the failures that actually happen
      # on a lock bump — without pulling another machine's closure (fulcrum's
      # CUDA/ComfyUI stack) onto this laptop every week.
      for host in $(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]'); do
        [ "$host" = "$this_host" ] && continue
        if ! nix eval --raw \
            ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath" >/dev/null; then
          broken="''${broken}system:$host "
        fi
      done

      for hc in $(nix eval --json ./home#homeConfigurations --apply builtins.attrNames | jq -r '.[]'); do
        case "$hc" in *"@$this_host") continue ;; esac
        if ! nix eval --raw \
            "./home#homeConfigurations.\"$hc\".activationPackage.drvPath" >/dev/null; then
          broken="''${broken}home:$hc "
        fi
      done

      # This host: build for real, so the result can be compared with what is
      # running. stderr flows to journalctl; only stdout (the path) is captured.
      sys_out=""
      if ! sys_out=$(nix build --no-link --print-out-paths \
          ".#nixosConfigurations.$this_host.config.system.build.toplevel"); then
        broken="''${broken}system:$this_host "
      fi
      home_out=""
      if ! home_out=$(nix build --no-link --print-out-paths \
          "./home#homeConfigurations.\"${config.home.username}@$this_host\".activationPackage"); then
        broken="''${broken}home:$this_host "
      fi

      if [ -n "$broken" ]; then
        notify_fail "Update check failed" "Would not build: $broken"
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
