{
  cmake,
  optee-client,
  optee-examples-ta,
  stdenv,
  lib,
}:

stdenv.mkDerivation {
  pname = "optee-examples-host";
  inherit (optee-examples-ta) version src;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ optee-client ];

  cmakeFlags = [ (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5") ];

  postPatch = ''
    substituteInPlace plugins/syslog/CMakeLists.txt \
      --replace-fail "/usr/lib" "\''${CMAKE_INSTALL_LIBDIR}"
  '';
}
