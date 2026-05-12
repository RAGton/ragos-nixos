{
  lib,
  stdenvNoCC,
  kryonix-brain-lightrag-src,
}:

stdenvNoCC.mkDerivation {
  pname = "kryonix-brain-lightrag";
  version = "src";

  src = kryonix-brain-lightrag-src;

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
  '';

  meta = {
    description = "Pinned source snapshot for Kryonix Brain LightRAG";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfree;
  };
}
