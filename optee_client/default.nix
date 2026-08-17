{
  fetchFromGitHub,
  lib,
  libuuid,
  pkg-config,
  stdenv,
  which,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "optee-client";
  version = "4.10.0";

  src = fetchFromGitHub {
    owner = "OP-TEE";
    repo = "optee_client";
    tag = finalAttrs.version;
    hash = "sha256-8oYQe5gEeDBPnouWk/GK740BqrUvpqT5XaivZ59IGyU=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    pkg-config
    which
  ];
  buildInputs = [ libuuid ];

  enableParallelBuilding = true;

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
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

  meta = {
    description = "Normal-world client APIs and supplicant for OP-TEE";
    homepage = "https://github.com/OP-TEE/optee_client";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
    mainProgram = "tee-supplicant";
  };
})
