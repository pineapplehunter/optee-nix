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
    optee-client.lib
  ];

  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs --build scripts
  '';

  preBuild = ''
    mkdir -p "$NIX_BUILD_TOP/optee-client-export"
    ln -s ${optee-client.dev}/include "$NIX_BUILD_TOP/optee-client-export/include"
    ln -s ${optee-client.lib}/lib "$NIX_BUILD_TOP/optee-client-export/lib"
  '';

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "TA_DEV_KIT_DIR=${optee-os-devkit.devkit-dir}"
    "OPTEE_CLIENT_EXPORT=$(NIX_BUILD_TOP)/optee-client-export"
    "O=build"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib/optee_armtz $out/lib/tee-supplicant/plugins
    find "$NIX_BUILD_TOP" -name '*.ta' -exec install -Dm644 {} $out/lib/optee_armtz/ \;
    find "$NIX_BUILD_TOP" -name '*.plugin' -exec install -Dm644 {} $out/lib/tee-supplicant/plugins/ \;
    install -Dm755 "$(find "$NIX_BUILD_TOP" -path '*/xtest/xtest' -type f -print -quit)" $out/bin/xtest
    runHook postInstall
  '';

  meta = {
    description = "OP-TEE sanity test suite and trusted applications";
    homepage = "https://github.com/OP-TEE/optee_test";
    license = lib.licenses.bsd2;
    platforms = [ "aarch64-linux" ];
    mainProgram = "xtest";
  };
})
