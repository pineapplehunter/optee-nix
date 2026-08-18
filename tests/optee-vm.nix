{
  lib,
  pkgsCross,
  qemu,
  testers,
}:

let
  targetPackages = pkgsCross.aarch64-multiplatform;
  firmware = targetPackages.optee-firmware;
  ftpmKernel = targetPackages.linuxPackages.kernel.override {
    structuredExtraConfig = with lib.kernel; {
      TCG_FTPM_TEE = module;
    };
  };
  ftpmKernelPackages = targetPackages.linuxPackagesFor ftpmKernel;
in
testers.nixosTest {
  name = "optee-vm";
  globalTimeout = 600;

  nodes.machine =
    { pkgs, ... }:
    {
      nixpkgs.pkgs = targetPackages;

      boot = {
        kernelPackages = ftpmKernelPackages;
        kernelModules = [ "tpm_ftpm_tee" ];
        kernelParams = [
          "console=ttyAMA0,38400"
          "keep_bootcon"
        ];
        loader.grub.enable = false;
      };

      environment.systemPackages = [
        pkgs.optee-client
        pkgs.optee-examples-host
        pkgs.optee-test
        pkgs.tpm2-tools
      ];

      systemd.services.tee-supplicant = {
        description = "OP-TEE supplicant";
        wantedBy = [ "multi-user.target" ];
        after = [ "dev-teepriv0.device" ];
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          ExecStartPre = "${pkgs.runtimeShell} -c 'until test -c /dev/teepriv0; do sleep 1; done'";
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.optee-client}/bin/tee-supplicant"
            "--fs-parent-path=/var/lib/tee"
            "--ta-path=${pkgs.optee-test}/lib/optee_armtz:${pkgs.optee-examples-ta}/lib/optee_armtz"
            "--plugin-path=${pkgs.optee-test}/lib/tee-supplicant/plugins"
          ];
          Restart = "on-failure";
          RestartSec = 1;
        };
      };

      virtualisation = {
        cores = 2;
        memorySize = 2048;
        qemu = {
          package = lib.mkForce qemu;
          options = [
            "-machine virt,secure=on,gic-version=3,virtualization=off"
            "-cpu max"
            "-bios ${firmware}/share/optee/firmware/flash.bin"
            "-serial file:secure-world.log"
          ];
        };
      };
    };

  interactive.qemu.package = lib.mkForce qemu;

  testScript = ''
    from datetime import timedelta

    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("tee-supplicant.service")
    machine.succeed("test -c /dev/tee0")
    machine.succeed("test -c /dev/teepriv0")
    machine.succeed("dmesg | grep -i optee")
    machine.succeed("optee_example_hello_world")
    machine.succeed("xtest -t regression 1001", timeout=timedelta(minutes=2))
    machine.wait_for_file("/dev/tpm0", timeout=timedelta(seconds=30))
    machine.succeed("test -c /dev/tpmrm0")
    machine.succeed("tpm2_getrandom --hex 8 | grep -Eq '^[[:xdigit:]]{16}$'")
  '';
}
