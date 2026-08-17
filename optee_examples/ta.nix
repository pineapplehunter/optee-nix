{
  stdenv,
  fetchFromGitHub,
  optee-os-devkit,
  buildPackages,
  optee-client,
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

  nativeBuildInputs = [ python-env ];
  buildInputs = [ optee-client ];

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "TA_DEV_KIT_DIR=${optee-os-devkit.devkit-dir}"
    "O=${placeholder "out"}"
  ];

  buildPhase = ''
    runHook preBuild

    for d in *; do
      [ -f $d/Makefile ] || continue;
      make -C $d $makeFlags
    done

    runHook postBuild
  '';

  dontInstall = true;
})
