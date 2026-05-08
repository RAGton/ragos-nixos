{
  rustPlatform,
  lib,
  kryonixHomeSrc,
}:
rustPlatform.buildRustPackage {
  pname = "kryonix-home";
  version = "0.1.0";

  src = kryonixHomeSrc;
  cargoLock.lockFile = "${kryonixHomeSrc}/Cargo.lock";

  meta = {
    description = "Kryonix Home Brain — scanner determinístico e organizador seguro da Home";
    license = lib.licenses.mit;
    mainProgram = "kryonix-home";
  };
}
