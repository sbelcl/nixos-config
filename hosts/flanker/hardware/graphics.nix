{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.hardware.nvidia = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NVIDIA GPU support with AMD integrated graphics.";
    };

    mode = mkOption {
      type = types.enum ["hybrid" "nvidia-only"];
      default = "hybrid";
      description = "Choose between hybrid (default) and NVIDIA-only graphics mode.";
    };
  };

  config = mkIf config.hardware.nvidia.enable {
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaSettings = true;
      open = false;

      prime = {
        sync.enable = config.hardware.nvidia.mode == "nvidia-only";
        offload.enable = config.hardware.nvidia.mode == "hybrid";
        offload.enableOffloadCmd = true;
        # GPU Bus IDs:
        # Note: 'intelBusId' is the attribute name from NixOS PRIME module,
        # but this system has AMD integrated GPU (not Intel)
        intelBusId = "PCI:6:0:0"; # AMD integrated GPU (attribute name is misleading)
        nvidiaBusId = "PCI:1:0:0"; # NVIDIA discrete GPU
      };
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      libvdpau
      mesa-demos
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
    ];
  };
}
