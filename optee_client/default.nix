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

stdenv.mkDerivation (final: {
  pname = "optee_os";
  version = "4.5.0-unstable-2025-02-24";
  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_client";
    rev = "6486773583b5983af8250a47cf07eca938e0e422";
    hash = "sha256-j4ZMaop3H3yNOWdrprEwM4ALN+o9C+smprrGjbotkEs=";
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
