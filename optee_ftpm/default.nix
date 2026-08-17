{
  buildPackages,
  fetchFromGitHub,
  lib,
  optee-os-devkit,
  stdenv,
}:

let
  uuid = "bc50d971-d4c9-42c4-82cb-343fb7f37896";
  ms-tpm-20-ref = fetchFromGitHub {
    owner = "microsoft";
    repo = "ms-tpm-20-ref";
    rev = "98b60a44aba79b15fcce1c0d1e46cf5918400f6a";
    hash = "sha256-s3VbhbFCcnXiZ+QZfC7b9Sw+ribYHNPEMcx8db9t09Q=";
  };
  python-env = buildPackages.python3.withPackages (ps: [ ps.cryptography ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "optee-ftpm";
  version = "4.10.0";

  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_ftpm";
    tag = finalAttrs.version;
    hash = "sha256-WGEpDd+yokJinTFtN7W6phUZHxBoRaJq+hvmSsY3HXU=";
  };

  strictDeps = true;
  nativeBuildInputs = [ python-env ];

  enableParallelBuilding = true;

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "TA_DEV_KIT_DIR=${optee-os-devkit.devkit-dir}"
    "CFG_MS_TPM_20_REF=${ms-tpm-20-ref}"
    "CFG_TA_MEASURED_BOOT=y"
    "O=build"
    "V=1"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 build/${uuid}.ta $out/lib/optee_armtz/${uuid}.ta
    install -Dm644 build/${uuid}.stripped.elf $out/libexec/optee-ftpm/${uuid}.stripped.elf
    runHook postInstall
  '';

  passthru = {
    earlyTa = "${finalAttrs.finalPackage}/libexec/optee-ftpm/${uuid}.stripped.elf";
    ta = "${finalAttrs.finalPackage}/lib/optee_armtz/${uuid}.ta";
  };

  meta = {
    description = "Firmware TPM trusted application for OP-TEE";
    homepage = "https://github.com/OP-TEE/optee_ftpm";
    license = lib.licenses.bsd2;
    platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };
})
