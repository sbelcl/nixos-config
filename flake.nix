{
  description = "NixOS configuration for flanker";

  inputs = {nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";};

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
    };
  };
}
