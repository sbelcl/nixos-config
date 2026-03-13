#
# ~/.nixos/modudles/software/greetd.nix
#
{ config, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Samodejni login uporabnika imnos
        user = "imnos";
        # Neposredno zagon Niri seje
        command = "niri-session";
      };
    };
  };
}

