{
  buildPackages,
  fetchFromGitHub,
  optee-os-devkit,
  stdenv,
}:

let
  ms-tpm-20-ref = fetchFromGitHub {
    owner = "microsoft";
    repo = "ms-tpm-20-ref";
    rev = "98b60a44aba79b15fcce1c0d1e46cf5918400f6a";
    hash = "sha256-s3VbhbFCcnXiZ+QZfC7b9Sw+ribYHNPEMcx8db9t09Q=";
  };

  python-env = buildPackages.python3.withPackages (ps: [ ps.cryptography ]);
in

stdenv.mkDerivation {
  pname = "optee_ftpm";
  version = "4.5.0-unstable-2025-02-06";

  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_ftpm";
    rev = "8675623483ba729b0153401da9d70a93b10e38ea";
    hash = "sha256-6ZrPwAL+nKGioIlxK9NCnsim9KpXoBMvdraFGq5v5TQ=";
  };

  nativeBuildInputs = [ python-env ];

  enableParallelBuilding = true;

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "TA_DEV_KIT_DIR=${optee-os-devkit.devkit-dir}"
    "CFG_MS_TPM_20_REF=${ms-tpm-20-ref}"
    "CFG_TA_MEASURED_BOOT=y"
    # "CFG_TA_DEBUG=y"
    "O=${placeholder "out"}"
    "V=1"
  ];

  dontInstall = true;
}
