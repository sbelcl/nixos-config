{ pkgs, ...  }:
{
  services.ollama = {
    enable = true;
    loadModels = [ "dolphin3" ];
  };
  environment.systemPackages = with pkgs; [
    ollama-cuda
  ];
}

