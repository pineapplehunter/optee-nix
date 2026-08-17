{
  buildPackages,
  dtc,
  fetchFromGitHub,
  lib,
  optee-ftpm,
  stdenv,

  # Configuration
  platform ? "vexpress-qemu_armv8a",
  enable-ftpm ? true,
  devkitOnly ? false,
}:

let
  python-env = buildPackages.python3.withPackages (ps: [
    ps.cryptography
    ps.pyelftools
  ]);
  taTarget =
    if stdenv.hostPlatform.isAarch64 then
      "ta_arm64"
    else if stdenv.hostPlatform.isAarch32 then
      "ta_arm32"
    else
      throw "optee-os only supports ARM targets";
in
stdenv.mkDerivation (finalAttrs: {
  pname = if devkitOnly then "optee-os-devkit" else "optee-os";
  version = "4.10.0";

  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_os";
    tag = finalAttrs.version;
    hash = "sha256-bmfuVScZsKYZFJTV0Nzqd3XshuwHOAhhQNN+5phfK3Q=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    dtc
    python-env
  ];

  enableParallelBuilding = true;

  makeFlags = [
    "O=build"
    "PLATFORM=${platform}"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "CROSS_COMPILE_core=${stdenv.cc.targetPrefix}"
    "CROSS_COMPILE_${taTarget}=${stdenv.cc.targetPrefix}"
    "CFG_USER_TA_TARGETS=${taTarget}"
    "CFG_TEE_CORE_LOG_LEVEL=3"
    "DEBUG=0"
    "CFG_IN_TREE_EARLY_TAS=trusted_keys/f04a0fe7-1f5d-4b9b-abf7-619b85b4ce8c"
    "CFG_ARM_GICV3=y"
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch64 [ "CFG_ARM64_core=y" ]
  ++ lib.optionals stdenv.hostPlatform.isAarch32 [ "CFG_ARM32_core=y" ]
  ++ lib.optionals enable-ftpm [ "EARLY_TA_PATHS=${optee-ftpm.earlyTa}" ]
  ++ lib.optionals devkitOnly [ "ta_dev_kit" ];

  postPatch = ''
    patchShebangs --build scripts/* ta/pkcs11/scripts/*
  '';

  installPhase =
    if devkitOnly then
      ''
        runHook preInstall
        cp -r build/export-${taTarget} $out
        runHook postInstall
      ''
    else
      ''
        runHook preInstall
        mkdir -p $out/share/optee
        install -Dm644 build/core/tee.elf $out/share/optee/tee.elf
        install -Dm644 build/core/tee.bin $out/share/optee/tee.bin
        install -Dm644 build/core/tee-header_v2.bin $out/share/optee/tee-header_v2.bin
        install -Dm644 build/core/tee-pager_v2.bin $out/share/optee/tee-pager_v2.bin
        install -Dm644 build/core/tee-pageable_v2.bin $out/share/optee/tee-pageable_v2.bin
        runHook postInstall
      '';

  passthru = lib.optionalAttrs devkitOnly {
    devkit-dir = "${finalAttrs.finalPackage}";
  };

  meta = {
    description =
      if devkitOnly then "OP-TEE trusted application development kit" else "Trusted OS for OP-TEE";
    homepage = "https://github.com/OP-TEE/optee_os";
    license = lib.licenses.bsd2;
    platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };
})
