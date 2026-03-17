{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Yandex Browser flake (using fork with wrapGAppsHook3 fix)
    yandex-browser = {
      url = "github:sbelcl/nix-yandex-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    yandex-browser,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations = {
      imnos = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix];
        extraSpecialArgs = {inherit inputs;};
      };
    };

    # Convenience outputs for easy building
    packages.${system} = {
      # Build with: nix build .#home or just nix build (since it's default)
      default = self.homeConfigurations.imnos.activationPackage;

      # Build with: nix build .#home
      home = self.homeConfigurations.imnos.activationPackage;

      # Build with: nix build .#imnos
      imnos = self.homeConfigurations.imnos.activationPackage;
    };

    # Another useful output: development shell
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.home-manager # Make home-manager available in the shell
      ];
    };
  };
}
