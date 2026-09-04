{
  description = "Home Manager configuration for flanker";

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
    };

    # `nix flake check` does not understand homeConfigurations. It is not a
    # standard flake output schema, so the command reports it as unknown and
    # never forces an activationPackage -- a check that passes while saying
    # nothing at all about whether either configuration evaluates.
    #
    # Re-exporting them here is what gives the command meaning. It is not
    # hypothetical: the default wallpaper used to be reached as
    # ../../../assets/..., which climbs out of this flake's source tree, so
    # both configurations failed pure evaluation while `nix flake check`
    # stayed green. That only ever worked because `nix ... ./home` is silently
    # widened to git+file:<repo>?dir=home, pulling the parent repo into the
    # store copy; the honest `path:` form failed outright.
    checks.${system} = {
      home-flanker = self.homeConfigurations."imnos@flanker".activationPackage;
    };

    # Development shell
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.home-manager];
    };
  };
}
