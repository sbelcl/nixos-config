{
  description = "NixOS configuration for flanker and fulcrum";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    comfyui-nix.url  = "github:utensils/comfyui-nix";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: {
    nixosConfigurations = {
      flanker = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/flanker/flanker.nix
        ];
      };

      fulcrum = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/fulcrum/fulcrum.nix
        ];
      };
    };
  };
}
