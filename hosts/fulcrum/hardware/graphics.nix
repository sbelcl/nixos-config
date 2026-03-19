#
# ~/.nixos/hosts/fulcrum/hardware/graphics.nix
#
# Gaming rig with single NVIDIA GPU (RTX 3080 Ti)
# No hybrid/PRIME setup needed - direct NVIDIA output
#
{
  lib,
  config,
  pkgs,
  ...
}: {
  # Video driver for X11/Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Required for Wayland compositors
    modesetting.enable = true;

    # Power management - less critical on desktop, but still useful
    powerManagement.enable = false;

    # NVIDIA settings GUI
    nvidiaSettings = true;

    # Use proprietary driver (better gaming performance)
    open = false;

    # No PRIME config needed for single GPU
  };

  # Graphics libraries and 32-bit support for gaming
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Gaming and graphics packages
  environment.systemPackages = with pkgs; [
    # Vulkan
    vulkan-loader
    vulkan-tools
    vulkan-validation-layers

    # Video decode/encode
    libvdpau
    nvidia-vaapi-driver

    # Debug/testing (glxinfo is included in mesa-demos)
    mesa-demos
    libva-utils # vainfo — verify VA-API / hardware decode

    # Gaming utilities
    mangohud
    gamemode
  ];

  # Enable GameMode for gaming performance
  programs.gamemode.enable = true;
}
