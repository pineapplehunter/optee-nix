{
  cmake,
  optee-client,
  optee-examples-ta,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "optee-examples-host";
  inherit (optee-examples-ta) version src;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ optee-client ];

  postPatch = ''
    substituteInPlace plugins/syslog/CMakeLists.txt \
      --replace-fail "/usr/lib" "\''${CMAKE_INSTALL_LIBDIR}"
  '';
}
