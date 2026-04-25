{ pkgs, ... }:
{
  kryonix.vscode.extraSettings = {
    "symbols.hidesExplorerArrows" = false;
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.colorTheme" = "GitHub Dark Default";
    "workbench.productIconTheme" = "fluent-icons";
    "workbench.startupEditor" = "newUntitledFile";
    "workbench.editor.labelFormat" = "short";
    "workbench.editor.editorActionsLocation" = "titleBar";
    "workbench.statusBar.visible" = true;
    "workbench.activityBar.location" = "top";
    "workbench.sideBar.location" = "right";
    "explorer.compactFolders" = false;
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;
    "explorer.confirmPasteNative" = false;
    "window.titleBarStyle" = "custom";
    "window.customTitleBarVisibility" = "auto";
    "window.nativeTabs" = true;
    "editor.fontSize" = 16;
    "editor.lineHeight" = 1.8;
    "editor.fontFamily" = "'Monocraft', monospace";
    "editor.fontLigatures" = true;
    "editor.rulers" = [
      80
      120
    ];
    "editor.renderLineHighlight" = "gutter";
    "editor.semanticHighlighting.enabled" = true;
    "editor.minimap.enabled" = false;
    "editor.scrollbar.horizontal" = "hidden";
    "editor.scrollbar.vertical" = "hidden";
    "editor.guides.bracketPairs" = true;
    "editor.guides.bracketPairsHorizontal" = true;
    "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
    "editor.formatOnSave" = true;
    "files.autoSave" = "afterDelay";
    "security.workspace.trust.untrustedFiles" = "open";
    "diffEditor.codeLens" = true;
    "diffEditor.ignoreTrimWhitespace" = true;
    "diffEditor.hideUnchangedRegions.enabled" = true;
    "continue.enableNextEdit" = false;
    "chat.agent.maxRequests" = 150;
    "chat.editing.confirmEditRequestRemoval" = false;
    "chat.tools.terminal.autoApprove" = {
      "sed" = true;
      "cargo check" = true;
      "cargo build" = true;
      "cargo run" = true;
      "cargo test" = true;
      "cargo clippy" = true;
      "cargo fix" = true;
      "cargo update" = true;
      "cargo tree" = true;
      "rg" = true;
      "nix" = true;
      "rustfmt" = true;
      "/usr/bin/env" = true;
      "/bin/zsh" = true;
      "home-manager" = true;
      "nixos-rebuild" = true;
      "hostname" = true;
      "test" = true;
      "true" = true;
      "git config" = true;
      "ssh-add" = true;
      "nvidia-smi" = true;
      "journalctl" = true;
      "systemctl" = true;
      "egrep" = true;
      "lscpu" = true;
      "coredumpctl" = true;
    };
    "apc.font.family" = "Monocraft";
    "apc.electron" = {
      frame = false;
      transparent = true;
      titleBarStyle = "hidden";
      backgroundColor = "#00000000";
    };
    "apc.header" = {
      height = 36;
    };
    "apc.listRow" = {
      height = 24;
    };
    "glassit.alpha" = 230;
    "glassit.step" = 10;
    "apc.stylesheet" = {
      ".title-label > h2" = "display: none;";
      ".editor-actions" = "display: none;";
      ".pane-body" = "padding: 8px;";
      ".pane-header" = "padding: 0 8px;";
      ".window-icon.window-close" = "display: none !important;";
      ".window-title" = "opacity: 0.82;";
      "body" = {
        "background-color" = "rgba(7, 10, 15, 0.14)";
      };
    };
    "workbench.colorCustomizations" = {
      "activityBar.background" = "#0b101766";
      "editor.background" = "#0b10174d";
      "editorGroupHeader.tabsBackground" = "#00000000";
      "panel.background" = "#0b101766";
      "sideBar.background" = "#0b101766";
      "sideBarSectionHeader.background" = "#00000033";
      "statusBar.background" = "#0b101780";
      "statusBar.debuggingBackground" = "#0b101780";
      "statusBar.noFolderBackground" = "#0b101780";
      "tab.activeBackground" = "#00000000";
      "tab.inactiveBackground" = "#00000000";
    };
    "[rust]" = {
      "editor.formatOnSave" = true;
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
    };
    "rust-analyzer.check.command" = "clippy";
    "[dockercompose]" = {
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
      "editor.autoIndent" = "advanced";
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "[github-actions-workflow]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "python.defaultInterpreterPath" = "/bin/python";
    "github.copilot.nextEditSuggestions.enabled" = true;
    "chat.viewSessions.orientation" = "stacked";
    "lldb.suppressUpdateNotifications" = true;
    "http.systemCertificatesNode" = true;
  };

  kryonix.vscode.extraExtensions = [
    "Continue.continue"
    "GitHub.copilot"
    "GitHub.copilot-chat"
    "GitHub.github-vscode-theme"
    "PKief.material-icon-theme"
    "drcika.apc-extension"
    "miguelsolorio.fluent-icons"
    "ms-vscode-remote.remote-ssh"
    "redhat.vscode-yaml"
    "s-nlf-fh.glassit"
    "vadimcn.vscode-lldb"
  ];

  home.packages = [
    pkgs.monocraft
  ];
}
