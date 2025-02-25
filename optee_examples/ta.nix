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

stdenv.mkDerivation {
  pname = "optee-examples-ta";
  version = "4.5.0-unstable-2025-01-10";

  src = fetchFromGitHub {
    owner = "linaro-swg";
    repo = "optee_examples";
    rev = "5306d2c7c618bb4a91df17a2d5d79ae4701af4a3";
    hash = "sha256-LQGPsy1OE7trk4s378Y8MWAdZ0B72aUJ24yy8rl5k2c=";
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
}
