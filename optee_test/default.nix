{
  buildPackages,
  fetchFromGitHub,
  lib,
  openssl,
  optee-client,
  optee-os-devkit,
  stdenv,
}:

let
  python-env = buildPackages.python3.withPackages (ps: [ ps.cryptography ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "optee-test";
  version = "4.10.0";

  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_test";
    tag = finalAttrs.version;
    hash = "sha256-WWxE6DxHDOds/SfGbNhTJVmhND3XhIPRxuln+pKYCnk=";
  };

  strictDeps = true;
  nativeBuildInputs = [ python-env ];
  buildInputs = [
    openssl
    optee-client
  ];

  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs --build scripts
  '';

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "TA_DEV_KIT_DIR=${optee-os-devkit.devkit-dir}"
    "OPTEE_CLIENT_EXPORT=${optee-client.dev}"
    "O=build"
    "TA_DIR=${placeholder "out"}/lib/optee_armtz"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 host/xtest/build/xtest/xtest $out/bin/xtest
    install -Dm755 host/supp_plugin/build/supp_plugin/*.plugin -t $out/lib/tee-supplicant/plugins
    mkdir -p $out/lib/optee_armtz
    find ta -name '*.ta' -exec install -Dm644 {} $out/lib/optee_armtz/ \;
    runHook postInstall
  '';

  meta = {
    description = "OP-TEE sanity test suite and trusted applications";
    homepage = "https://github.com/OP-TEE/optee_test";
    license = with lib.licenses; [
      bsd2
      gpl2Only
    ];
    platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];
    mainProgram = "xtest";
  };
})
