{
  writeShellApplication,
  callPackage,
  coreutils,
  curl,
  gitMinimal,
  gnugrep,
  gnused,
  jq,
  libvirt,
  nh,
  nix,
  nvd,
  nixos-install-tools,
  python3,
  util-linux,
  uv,
  stdenv,
  lib,
  libffi,
  openssl,
  zlib,
  openrgb,
  kryonixHome,
  kryonix-hardware-probe,
  kryonix-disk-planner,
  kryonix-installer,
}:
let
  runtimeLibPath = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    zlib
    libffi
    openssl
  ];
in
writeShellApplication {
  name = "kryonix";
  runtimeInputs = [
    coreutils
    curl
    gitMinimal
    gnugrep
    gnused
    jq
    libvirt
    nh
    nix
    nvd
    nixos-install-tools
    python3
    util-linux
    uv
    openrgb
    kryonixHome
    kryonix-hardware-probe
    kryonix-disk-planner
    kryonix-installer
  ];
  text =
    "set -euo pipefail\ntrap 'stty sane opost onlcr echo icanon isig 2>/dev/null || true' EXIT INT TERM\n"
    + "runtimeLibPath=\"${runtimeLibPath}\"\n"
    + builtins.readFile ./kryonix-cli/core.sh
    + builtins.readFile ./kryonix-cli/nixos.sh
    + builtins.readFile ./kryonix-cli/git.sh
    + builtins.readFile ./kryonix-cli/brain.sh
    + builtins.readFile ./kryonix-cli/services.sh
    + builtins.readFile ./kryonix-cli/remote.sh
    + builtins.readFile ./kryonix-cli/home.sh
    + builtins.readFile ./kryonix-cli/installer.sh
    + builtins.readFile ./kryonix-cli/main.sh;
  meta = {
    description = "Kryonix Unified CLI — System management, AI, and Home Brain interface";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
