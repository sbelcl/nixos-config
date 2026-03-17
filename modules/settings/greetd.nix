#
# ~/.nixos/modules/settings/greetd.nix
#
# Greetd display manager - minimal, auto-login to Niri
#
{
  config,
  lib,
  ...
}:
with lib; {
  options.displayManager.greetd = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable greetd display manager with auto-login to Niri";
    };
  };

  config = mkIf config.displayManager.greetd.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          # Auto-login user imnos
          user = "imnos";
          # Start Niri session
          command = "niri-session";
        };
      };
    };
  };
}
