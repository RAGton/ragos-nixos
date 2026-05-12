{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "kryonix-hardware-probe";
  version = "0.1.0";

  src = ./kryonix-hardware-probe;

  cargoLock = {
    lockFile = ./kryonix-hardware-probe/Cargo.lock;
  };

  meta = with lib; {
    description = "Kryonix hardware detection tool";
    homepage = "https://github.com/RAGton/kryonix";
    license = lib.licenses.unfree;
    maintainers = [ ];
  };
}
