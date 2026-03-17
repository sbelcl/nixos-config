{
  description = "Home Manager configuration for flanker and fulcrum";

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
    mkHome = hostModule:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix hostModule];
        extraSpecialArgs = {inherit inputs;};
      };
  in {
    homeConfigurations = {
      "imnos@flanker" = mkHome ./hosts/flanker.nix;
      "imnos@fulcrum" = mkHome ./hosts/fulcrum.nix;
    };

    # Development shell
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.home-manager];
    };
  };
}
