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

    # Prebuilt nix-index database, refreshed upstream twice a week. Without
    # it, `nix-locate` needs a local `nix-index` run (tens of minutes, and
    # stale the moment nixpkgs moves) before the command-not-found handler
    # can answer anything.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # snappy-switcher: pinned — upstream commit 06eb4c5 (v4.0.0) broke its own
    # substituteInPlace by removing /usr/local from the systemd unit but not
    # from the derivation. Un-pin once upstream fixes the mismatch.
    snappy-switcher = {
      url = "github:OpalAayan/snappy-switcher/0957cd612fadf80fa95034515cb6fa2c163e497e";
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
