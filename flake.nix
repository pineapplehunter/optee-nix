{
  description = "A basic package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      treefmt-nix,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
    in
    {
      overlays.default = final: prev: {
        optee-os = final.callPackage ./optee_os { };
        optee-os-devkit =
          (final.optee-os.override {
            enable-ftpm = false;
          }).overrideAttrs
            (old: {
              pname = old.pname + "-devkit";
              makeFlags = old.makeFlags ++ [ "ta_dev_kit" ];
            });
        optee-ftpm = final.callPackage ./optee_ftpm { };
        optee-client = final.callPackage ./optee_client { };

        # examples
        optee-examples-ta = final.callPackage ./optee_examples/ta.nix { };
        optee-examples-host = final.callPackage ./optee_examples/host.nix { };
      };

      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        rec {
          inherit (pkgs.pkgsCross.aarch64-multiplatform)
            optee-os
            optee-ftpm
            optee-client
            optee-examples-ta
            optee-examples-host
            ;
          default = optee-os;
        }
      );

      checks = eachSystem (system: self.packages.${system});

      formatter = eachSystem (
        system:
        (treefmt-nix.lib.evalModule (pkgsFor system) {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }).config.build.wrapper
      );

      # legacyPackages = eachSystem pkgsFor;
    };
}
