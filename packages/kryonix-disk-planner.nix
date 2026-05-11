{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "kryonix-disk-planner";
  version = "0.1.0";

  src = ./kryonix-disk-planner;

  cargoLock = {
    lockFile = ./kryonix-disk-planner/Cargo.lock;
  };

  meta = with lib; {
    description = "Kryonix disk planning tool";
    homepage = "https://github.com/RAGton/kryonix";
    license = licenses.mit;
    maintainers = [ ];
  };
}
