#
# ~/.nixos/modules/software/ollama.nix
#
{...}: {
  services.ollama = {
    enable = true;
    acceleration = "cuda";   # NVIDIA GPU inference
  };
}
