{
  description = "A basic package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, ... }: {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake.overlays.default = final: prev: {
          optee-os = final.callPackage ./optee_os { };
          optee-os-devkit = final.optee-os.override {
            enable-ftpm = false;
            devkitOnly = true;
          };
          optee-ftpm = final.callPackage ./optee_ftpm { };
          optee-client = final.callPackage ./optee_client { };

          # examples
          optee-examples-ta = final.callPackage ./optee_examples/ta.nix { };
          optee-examples-host = final.callPackage ./optee_examples/host.nix { };
        };

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          let
            targetPackages = pkgs.pkgsCross.aarch64-multiplatform;
          in
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                config.flake.overlays.default
              ];
            };

            packages = rec {
              inherit (targetPackages)
                optee-client
                optee-examples-host
                optee-examples-ta
                optee-ftpm
                optee-os
                optee-os-devkit
                ;
              default = optee-os;
            };

            checks.package-set = pkgs.callPackage ./tests/package-set.nix {
              pkgsCross = targetPackages;
            };

            formatter = pkgs.nixfmt-tree;
          };
      }
    );
}
