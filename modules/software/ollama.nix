#
# ~/.nixos/modules/software/ollama.nix
#
{pkgs, ...}: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;   # NVIDIA GPU inference
  };
}
