{ pkgs, lib, ... }:
{
  # Provide a "warp-terminal" module that uses wezterm as a modern terminal backend.
  # It installs wezterm and creates a small wrapper `warp-terminal` in $HOME/bin
  # Install the actual `warp-terminal` package (not wezterm) so the correct
  # binary is provided by Nix.
  home.packages = [ pkgs.warp-terminal ];

  # Note: we don't enable `programs.wezterm` here because the user requested
  # `warp-terminal` which provides its own binary.

}
