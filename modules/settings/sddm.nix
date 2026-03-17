#
# ~/.nixos/modules/settings/sddm.nix
#
# SDDM display manager - good for Plasma integration
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.displayManager.sddm = {
    enable = mkEnableOption "SDDM display manager";
  };

  config = mkIf config.displayManager.sddm.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;

      # Theme settings (optional - uses breeze by default with Plasma)
      # theme = "breeze";
    };

    # Ensure X server is available for SDDM
    services.xserver.enable = true;
  };
}
