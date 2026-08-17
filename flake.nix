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

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                config.flake.overlays.default
              ];
            };

            packages = rec {
              inherit (pkgs.pkgsCross.aarch64-multiplatform)
                optee-os
                optee-ftpm
                optee-client
                optee-examples-ta
                optee-examples-host
                ;
              default = optee-os;
            };

            formatter = pkgs.nixfmt-tree;
          };
      }
    );
}
