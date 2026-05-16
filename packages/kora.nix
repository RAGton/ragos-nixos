{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "kora";
  version = "0.1.0";

  src = ../packages/kora;

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
  '';

  meta = {
    description = "Kora — Kryonix Personal Assistant (gateway/orchestrator)";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfree;
  };
}
