# Hardware configuration placeholder para o host "inspiron-nina"
#
# Substitua este arquivo pelo `hardware-configuration.nix` real gerado na
# máquina da Nina quando você mover os arquivos dela para este repo.
#
# Mantemos apenas o mínimo necessário para o host continuar avaliando.
{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
