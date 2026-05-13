{
  pkgs,
  lib,
  ...
}:

# Wrapper para o llama-cpp com suporte CUDA habilitado
pkgs.llama-cpp.override {
  cudaSupport = true;
}
