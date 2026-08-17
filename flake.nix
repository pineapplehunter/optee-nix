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
          optee = rec {
            version = "4.10.0";
            os = final.callPackage ./optee_os { };
            os-devkit = os.override {
              enable-ftpm = false;
              devkitOnly = true;
            };
            ftpm = final.callPackage ./optee_ftpm { };
            client = final.callPackage ./optee_client { };
            uboot = final.ubootQemuAarch64.overrideAttrs {
              version = "2025.07";
              src = final.fetchFromGitHub {
                owner = "u-boot";
                repo = "u-boot";
                tag = "v2025.07";
                hash = "sha256-X+JhVkDudkvQo08hGwAChOeMZZR+iunT9aU6tSAuMmg=";
              };
            };
            firmware = final.callPackage ./optee_firmware { };
            test = final.callPackage ./optee_test { };
            examples-ta = final.callPackage ./optee_examples/ta.nix { };
            examples-host = final.callPackage ./optee_examples/host.nix { };
          };

          # Flat aliases preserve the package names used by existing consumers.
          optee-os = final.optee.os;
          optee-os-devkit = final.optee.os-devkit;
          optee-ftpm = final.optee.ftpm;
          optee-client = final.optee.client;
          optee-uboot = final.optee.uboot;
          optee-firmware = final.optee.firmware;
          optee-test = final.optee.test;
          optee-examples-ta = final.optee.examples-ta;
          optee-examples-host = final.optee.examples-host;
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
                optee-firmware
                optee-ftpm
                optee-os
                optee-os-devkit
                optee-test
                optee-uboot
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
