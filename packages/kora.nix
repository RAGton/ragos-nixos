{
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication {
  pname = "kora";
  version = "0.1.0";
  pyproject = true;

  src = ../packages/kora;

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    fastapi
    uvicorn
    httpx
    pydantic
    python-dotenv
  ];

  meta = {
    description = "Kora — Kryonix Personal Assistant (gateway/orchestrator)";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfree;
  };
}
