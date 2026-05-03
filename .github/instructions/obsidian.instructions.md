---
applyTo: "modules/home-manager/programs/obsidian/**/*.nix,context/RUNBOOKS/obsidian-vault-ops.md,skills/obsidian-memory/SKILL.md"
---

Separe três superfícies do Obsidian: app desktop, CLI do Obsidian e Headless Sync.

Não assuma que Headless Sync está instalado só porque o app desktop existe.

Quando documentar operação local, trate o vault como dado do usuário. Não invente caminhos de vault sem confirmação no host.

Se o problema for launcher/desktop entry, valide o `Exec` publicado e o comportamento real no host. Se o problema for CLI/Headless, use apenas comandos que existam na documentação oficial do Obsidian.
