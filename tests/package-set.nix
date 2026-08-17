{
  pkgsCross,
  runCommand,
}:

let
  inherit (pkgsCross)
    optee-client
    optee-examples-host
    optee-examples-ta
    optee-firmware
    optee-ftpm
    optee-os
    optee-os-devkit
    optee-uboot
    ;
in
runCommand "optee-package-set-check" { } ''
  test -f ${optee-os}/share/optee/tee.elf
  test -f ${optee-os}/share/optee/tee.bin
  test -f ${optee-os}/share/optee/tee-header_v2.bin
  test -f ${optee-os}/share/optee/tee-pager_v2.bin
  test -f ${optee-os}/share/optee/tee-pageable_v2.bin

  test -f ${optee-uboot}/u-boot.bin
  test -f ${optee-firmware}/share/optee/firmware/bl1.bin
  test -f ${optee-firmware}/share/optee/firmware/bl2.bin
  test -f ${optee-firmware}/share/optee/firmware/bl31.bin
  test -f ${optee-firmware}/share/optee/firmware/fip.bin

  test -f ${optee-os-devkit.devkit-dir}/mk/ta_dev_kit.mk
  test -f ${optee-os-devkit.devkit-dir}/include/tee_api.h
  test -f ${optee-os-devkit.devkit-dir}/lib/libutee.a

  test -x ${optee-client}/bin/tee-supplicant
  test -f ${optee-client.lib}/lib/libteec.so
  test -f ${optee-client.dev}/include/tee_client_api.h

  test -f ${optee-ftpm.ta}
  test -f ${optee-ftpm.earlyTa}

  test -f ${optee-examples-ta}/lib/optee_armtz/8aaaf200-2450-11e4-abe2-0002a5d5c51b.ta
  test -x ${optee-examples-host}/bin/optee_example_hello_world

  touch $out
''
