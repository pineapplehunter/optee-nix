{
  buildArmTrustedFirmware,
  lib,
  optee-os,
  optee-uboot,
}:

buildArmTrustedFirmware {
  pname = "optee-firmware";
  platform = "qemu";
  installDir = "$out/share/optee/firmware";

  extraMakeFlags = [
    "BL32=${optee-os}/share/optee/tee-header_v2.bin"
    "BL32_EXTRA1=${optee-os}/share/optee/tee-pager_v2.bin"
    "BL32_EXTRA2=${optee-os}/share/optee/tee-pageable_v2.bin"
    "BL33=${optee-uboot}/u-boot.bin"
    "SPD=opteed"
    "BL32_RAM_LOCATION=tdram"
    "QEMU_USE_GIC_DRIVER=QEMU_GICV3"
    "DEBUG=0"
    "LOG_LEVEL=30"
    "all"
    "fip"
  ];

  filesToInstall = [
    "build/qemu/release/bl1.bin"
    "build/qemu/release/bl2.bin"
    "build/qemu/release/bl31.bin"
    "build/qemu/release/fip.bin"
  ];

  extraMeta = {
    description = "Trusted Firmware-A boot chain with OP-TEE for QEMU virt";
    homepage = "https://optee.readthedocs.io";
    license = lib.licenses.bsd3;
    platforms = [ "aarch64-linux" ];
  };
}
