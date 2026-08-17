{
  buildPackages,
  fetchFromGitHub,
  lib,
  optee-os-devkit,
  stdenv,
}:

let
  python-env = buildPackages.python3.withPackages (ps: [ ps.cryptography ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "optee-examples-ta";
  version = "4.10.0";

  src = fetchFromGitHub {
    owner = "linaro-swg";
    repo = "optee_examples";
    tag = finalAttrs.version;
    hash = "sha256-8SaicPUvU5lSJeSOhmd8L3bRiRpQrHteoYAoPmNpLJ8=";
  };

  strictDeps = true;
  nativeBuildInputs = [ python-env ];

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "TA_DEV_KIT_DIR=${optee-os-devkit.devkit-dir}"
  ];

  buildPhase = ''
    runHook preBuild

    for d in *; do
      [ -f "$d/Makefile" ] || continue
      make -C "$d/ta" O="$NIX_BUILD_TOP/ta-build/$d" $makeFlags
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/optee_armtz
    find "$NIX_BUILD_TOP/ta-build" -name '*.ta' -exec install -Dm644 {} $out/lib/optee_armtz/ \;
    runHook postInstall
  '';

  meta = {
    description = "Trusted applications from the OP-TEE examples";
    homepage = "https://github.com/linaro-swg/optee_examples";
    license = lib.licenses.bsd2;
    platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };
})
