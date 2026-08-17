# optee-nix

Nix packages and a NixOS VM test for the
[OP-TEE](https://www.op-tee.org/) trusted execution environment.

The flake cross-compiles an AArch64 QEMU guest and boots it through Trusted
Firmware-A, OP-TEE, and U-Boot. It packages normal-world clients, example
trusted applications, the fTPM trusted application, and the upstream `xtest`
test suite.

> [!WARNING]
> This repository is a development and test environment, not a production
> secure-boot system. The QEMU platform, default OP-TEE test keys, debug logging,
> and emulated firmware do not provide a hardware root of trust. Do not treat
> secrets processed by this VM as protected from its host.

## Supported systems

The automated VM is supported on an `x86_64-linux` host and runs an
`aarch64-linux` guest under QEMU TCG. Package outputs also evaluate when the
flake is used from an AArch64 Linux host, but that path is not covered by the VM
check.

Requirements:

- Nix with flakes enabled
- enough disk space for a cross-compiled AArch64 NixOS closure
- support for running NixOS VM tests

## Run the interactive VM

```console
nix run
```

This opens the NixOS test driver's Python REPL. Start the machine and attach to
its normal-world serial console with:

```python
start_all()
machine.shell_interact()
```

Use <kbd>Ctrl-D</kbd> to leave the shell and then the REPL. The driver cleans up
the VM. Runtime QEMU options can be overridden without rebuilding, for example:

```console
QEMU_OPTS='-m 4G -smp 4' nix run
```

The default is 2 GiB RAM and two virtual CPUs.

## Package outputs

```console
nix build .#optee-os             # OP-TEE secure-world images
nix build .#optee-os-devkit      # trusted application development kit
nix build .#optee-client         # libteec and tee-supplicant
nix build .#optee-ftpm           # fTPM trusted application
nix build .#optee-examples-ta    # example trusted applications
nix build .#optee-examples-host  # example normal-world clients
nix build .#optee-test           # xtest, test TAs, and supplicant plugin
nix build .#optee-uboot          # manifest-compatible QEMU U-Boot
nix build .#optee-firmware       # TF-A FIP and flash image
```

The reusable overlay is exported as `overlays.default`. Packages are grouped
under `pkgs.optee` (`os`, `client`, `ftpm`, `test`, `firmware`, and related
components). Flat package aliases are retained for existing consumers.

## Architecture

The VM follows the upstream OP-TEE QEMU v8 boot flow:

1. QEMU maps the combined TF-A flash image into secure flash.
2. TF-A loads OP-TEE as BL32 and U-Boot as BL33.
3. U-Boot obtains the NixOS kernel and initrd from QEMU firmware configuration.
4. Linux discovers the OP-TEE interface and creates `/dev/tee0` and
   `/dev/teepriv0`.
5. `tee-supplicant` serves packaged TAs from their immutable Nix store paths.

The component baseline follows the OP-TEE 4.10.0 stable manifest: TF-A 2.14.0,
U-Boot 2025.07, and OP-TEE OS/client/examples/tests 4.10.0. The U-Boot QEMU
ramdisk load address is adjusted to avoid overlap with the NixOS kernel image.
Unmodified nixpkgs QEMU is used.

## Test and develop

```console
nix fmt -- --ci
nix flake check --all-systems --no-build
nix build .#checks.x86_64-linux.package-set --no-link
nix build .#checks.x86_64-linux.optee-vm --no-link
nix develop
```

The VM check verifies normal- and secure-world boot, the TEE devices,
`tee-supplicant`, kernel OP-TEE initialization, the hello-world client/TA round
trip, and bounded regression test `xtest -t regression 1001`. PKCS#11 test 1001
is intentionally outside that filtered baseline because the guest does not yet
install the PKCS#11 TA.

The development shell provides nixfmt-tree and ShellCheck.

## Updating dependencies

1. Select an OP-TEE stable manifest and update all OP-TEE component tags as one
   coordinated set.
2. Update TF-A, U-Boot, QEMU assumptions, and `ms-tpm-20-ref` to the revisions
   selected by that manifest.
3. Update source hashes and `flake.lock`.
4. Recheck the U-Boot load-address adjustment and remove it if upstream no
   longer needs it.
5. Run formatting, evaluation, the package-set check, and the complete VM check
   shown above.
6. Review upstream release and security notes before using the new baseline.

## Current limitations

- Only the AArch64 QEMU virt platform is integrated.
- The VM uses software emulation and development keys.
- The automated baseline runs a focused `xtest` subset, not every upstream test.
- fTPM is embedded in OP-TEE and packaged for normal-world loading, but an
  end-to-end TPM smoke test is not implemented yet.
