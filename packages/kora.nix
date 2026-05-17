{
  lib,
  python3Packages,
  whisper-cpp,
  piper-tts,
  alsa-utils,
  ffmpeg,
  makeWrapper,
}:

python3Packages.buildPythonApplication {
  pname = "kora";
  version = "0.1.0";
  pyproject = true;

  src = ../packages/kora;

  build-system = with python3Packages; [
    hatchling
  ];

  nativeBuildInputs = [ makeWrapper ];

  dependencies = with python3Packages; [
    fastapi
    uvicorn
    httpx
    pydantic
    python-dotenv
    pyaudio
    pyopen-wakeword
    numpy
    edge-tts
  ];

  postInstall = ''
    wrapProgram $out/bin/kora \
      --prefix PATH : ${
        lib.makeBinPath [
          whisper-cpp
          piper-tts
          alsa-utils
          ffmpeg
        ]
      } \
      --set-default KORA_WHISPER_BIN "whisper-cli"
  '';

  meta = {
    description = "Kora — Kryonix Personal Assistant (gateway/orchestrator)";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfree;
  };
}
