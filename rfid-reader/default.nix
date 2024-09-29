{
  stdenv
}:
stdenv.mkDerivation {
  NIX_CFLAGS_COMPILE = "-Wno-format-security";
  name = "rfid-reader";
  src = ./.;
  buildPhase = ''
    $CC ./rfid-reader.c -o rfid-reader
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv ./rfid-reader $out/bin/rfid-reader
  '';
}
