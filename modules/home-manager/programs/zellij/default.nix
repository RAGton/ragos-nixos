{ pkgs, ... }:
{
  # Install Zellij and provide a translated config from the previous tmux settings.
  home.packages = [ pkgs.zellij ];

  # Create a sensible default zellij config translating tmux settings:
  # - prefix: Ctrl+q
  # - mouse: enabled
  # - scrollback/history: 10000
  # - pane navigation with Ctrl-h/j/k/l
  # - basic resize shortcuts
  home.file.".config/zellij/config.kdl".text = ''
// Translated zellij configuration (generated from tmux settings).
// Review and adapt at ~/.config/zellij/config.kdl

general {
  // lines of scrollback
  scrollback_lines 10000
  // enable mouse support
  enable_mouse true
}

// Keybinds: map many tmux-style bindings to zellij equivalents.
// Note: zellij key names and commands are stable but may differ per version.
keybinds {
  // Use Ctrl-q as a leader-like single-key prefix mapping is not identical in zellij,
  // but we can map frequently used combinations directly.
  normal {
    // Pane navigation: Ctrl-h/j/k/l
    "Ctrl-h" = "MoveFocusLeft"
    "Ctrl-j" = "MoveFocusDown"
    "Ctrl-k" = "MoveFocusUp"
    "Ctrl-l" = "MoveFocusRight"

    // Splits similar to tmux: prefix+v / prefix+s replaced by direct combos
    "Ctrl-\\" = "SplitVertical"
    "Ctrl-|" = "SplitHorizontal"
  }

  pane {
    // Resize with Shift+Arrow similar to tmux binds
    "Shift-Down" = "ResizePaneDown 8"
    "Shift-Up" = "ResizePaneUp 8"
    "Shift-Left" = "ResizePaneLeft 8"
    "Shift-Right" = "ResizePaneRight 8"
  }
}

// Simple layout as default
layout "default" {
  pane 1
}
'';

  # Provide a minimal user-friendly launcher script to start zellij in a new wezterm window
  home.file."bin/start-zellij".text = ''#!/bin/sh
exec ${pkgs.zellij}/bin/zellij "$@"
'';
  # mode omitted for compatibility with older Home Manager versions
}
