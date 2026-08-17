{
  cmake,
  lib,
  optee-client,
  optee-examples-ta,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "optee-examples-host";
  inherit (optee-examples-ta) version src;

  strictDeps = true;
  nativeBuildInputs = [ cmake ];
  buildInputs = [ optee-client ];

  cmakeFlags = [ (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5") ];

  postPatch = ''
    substituteInPlace plugins/syslog/CMakeLists.txt \
      --replace-fail "/usr/lib" "\''${CMAKE_INSTALL_LIBDIR}"
  '';

  meta = {
    description = "Normal-world host applications from the OP-TEE examples";
    homepage = "https://github.com/linaro-swg/optee_examples";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
  };
}
