{
  buildPackages,
  dtc,
  fetchFromGitHub,
  stdenv,
  optee-ftpm,
  lib,

  # config
  platform ? "vexpress-qemu_armv8a",
  enable-ftpm ? true,
}:

let
  python-env = (
    buildPackages.python3.withPackages (ps: [
      ps.cryptography
      ps.pyelftools
    ])
  );
in

stdenv.mkDerivation (final: {
  pname = "optee_os";
  version = "4.5.0-unstable-2025-02-24";
  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_os";
    rev = "a137cc88644e179dfc9a6f67f9d12d6a4b57ed37";
    hash = "sha256-yz8W7dmlqB5v3SjZCOZHcFUCCQ1E1IIVBE1dpVHkXIA=";
  };

  nativeBuildInputs = [
    python-env
    dtc
  ];

  enableParallelBuilding = true;

  makeFlags =
    [
      "O=${placeholder "out"}"
      "PLATFORM=${platform}"
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
      "CROSS_COMPILE_core=${stdenv.cc.targetPrefix}"
      "CFG_TEE_CORE_LOG_LEVEL=3"
      "DEBUG=0"
      "CFG_IN_TREE_EARLY_TAS=trusted_keys/f04a0fe7-1f5d-4b9b-abf7-619b85b4ce8c"
      "CFG_ARM_GICV3=y"
    ]
    ++ lib.optionals stdenv.hostPlatform.isAarch64 [
      "CROSS_COMPILE_ta_arm64=${stdenv.cc.targetPrefix}"
      "CFG_USER_TA_TARGETS=ta_arm64"
      "CFG_ARM64_core=y"
    ]
    ++ lib.optionals stdenv.hostPlatform.isAarch32 [
      "CROSS_COMPILE_ta_arm32=${stdenv.cc.targetPrefix}"
      "CFG_USER_TA_TARGETS=ta_arm32"
      "CFG_ARM32_core=y"
    ]
    ++ lib.optionals enable-ftpm [
      "EARLY_TA_PATHS=${optee-ftpm}/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf"
    ];

  postPatch = ''
    patchShebangs --build scripts/* ta/pkcs11/scripts/*
  '';

  dontInstall = true;

  passthru.devkit-dir =
    {
      aarch64-linux = "${final.finalPackage}/export-ta_arm64";
    }
    .${stdenv.hostPlatform.system};

  meta = { };
})
