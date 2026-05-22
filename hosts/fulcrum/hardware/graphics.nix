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

    # Power management — saves GPU memory to disk on suspend/hibernate.
    # Required for reliable wake from sleep on Wayland (RTX 3080 Ti).
    powerManagement.enable = true;

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

  # NVIDIA suspend/session fix for large VRAM (12 GB RTX 3080 Ti).
  # NVreg_PreserveVideoMemoryAllocations — keeps VRAM state across suspend and
  # session boundaries; without it, SDDM gets a dirty GPU after a game exits at
  # logout, causing a black screen.
  # NVreg_TemporaryFilePath — powerManagement.enable dumps VRAM to /tmp (tmpfs)
  # by default, which is too small for 12 GB. Redirect to /var/tmp (disk).
  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
    options nvidia NVreg_TemporaryFilePath=/var/tmp
  '';
}
