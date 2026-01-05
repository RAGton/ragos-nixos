{ ... }:
{
  # tmux module deprecated: functionality migrated to zellij module.
  # Keep a harmless stub so older references don't break imports.
  programs.tmux = {
    enable = false; # intentionally disabled
  };

  # If you want to permanently remove this file from the repo, delete it manually.
}
