#
# ~/.nixos/home/modules/hyprland/hyprpanel.nix
#
{ pkgs, inputs, lib, config, ... }: {

  options.hyprpanel.package = lib.mkOption {
    type        = lib.types.package;
    default     = inputs.hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default;
    description = "HyprPanel package to use. Override per-host to apply patches.";
  };

  config = let
    hp = config.hyprpanel.package;
  in {
    home.packages = [ hp ];

    # HyprPanel is launched directly from Hyprland's exec-once (config.nix)
    # rather than via a systemd service.  Launching it from exec-once avoids
    # the ~15-second systemd activation delay caused by waiting for
    # HYPRLAND_INSTANCE_SIGNATURE to propagate into the user session.
  };
}
