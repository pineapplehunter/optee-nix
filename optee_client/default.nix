{
  buildPackages,
  dtc,
  fetchFromGitHub,
  stdenv,
  optee-ftpm,
  lib,
  libuuid,
  which,
  pkg-config,
}:

let
  python-env = (
    buildPackages.python3.withPackages (ps: [
      ps.cryptography
      ps.pyelftools
    ])
  );
in

stdenv.mkDerivation (finalAttrs: {
  pname = "optee_os";
  version = "4.10.0";
  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_client";
    tag = finalAttrs.version;
    hash = "sha256-8oYQe5gEeDBPnouWk/GK740BqrUvpqT5XaivZ59IGyU=";
  };

  nativeBuildInputs = [
    # python-env
    # dtc
    which
    pkg-config
  ];

  buildInputs = [ libuuid ];

  enableParallelBuilding = true;

  makeFlags = [
    "DESTDIR="
    "SBINDIR=${placeholder "out"}/sbin"
    "LIBDIR=${placeholder "lib"}/lib"
    "INCLUDEDIR=${placeholder "dev"}/include"
  ];

  outputs = [
    "out"
    "lib"
    "dev"
  ];

  meta = { };
})
