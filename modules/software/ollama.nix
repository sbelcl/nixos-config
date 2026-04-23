#
# ~/.nixos/modules/software/ollama.nix
#
{pkgs, ...}: {
  services.ollama = {
    enable = true;
    # Temporarily use CPU-only Ollama while ollama-cuda fails to build on unstable.
    package = pkgs.ollama;
  };
}
