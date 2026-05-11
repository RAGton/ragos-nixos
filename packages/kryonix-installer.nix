{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "kryonix-installer";
  version = "0.1.0";

  src = ./kryonix-installer;

  cargoLock = {
    lockFile = ./kryonix-installer/Cargo.lock;
  };

  meta = with lib; {
    description = "Kryonix installer backend (Axum)";
    homepage = "https://github.com/RAGton/kryonix";
    license = licenses.mit;
    maintainers = [ ];
  };
}
