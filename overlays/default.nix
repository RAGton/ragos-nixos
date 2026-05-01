# Overlays do repo (extensões/alterações de pacotes)
# Autor: rag
#
# O que é
# - Conjunto de overlays reutilizáveis aplicados via `nixpkgs.overlays`.
# - Aqui ficam overrides pontuais (ex.: pin de pacote, patch temporário).
#
# Por quê
# - Mantém customizações isoladas do restante dos módulos.
# - Facilita reuso entre hosts e evita duplicação.
#
# Como
# - Cada overlay é uma função `final: prev: { ... }`.
# - Hosts/módulos escolhem quais overlays aplicar (ordem importa).
#
# Riscos
# - Overlays podem mascarar bugs do upstream e dificultar upgrades.
# - Patches temporários devem ser revisados/removidos quando o upstream corrigir.
{ inputs, ... }:
{
  # Quando aplicado, o conjunto estável do nixpkgs (declarado nos inputs da flake)
  # fica acessível via 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # OpenRGB bleeding-edge (git) pinado em um commit.
  # Remova quando o nixpkgs voltar a carregar a versão desejada sem pin manual.
  openrgb-git = final: prev: {
    openrgb-git = prev.openrgb.overrideAttrs (
      old:
      let
        rev = "2a1b7a9e2e58c82cbd1e64131644bc2b208f9ba2";
      in
      {
        pname = "openrgb";
        version = "git-${builtins.substring 0 8 rev}";
        src = prev.fetchFromGitHub {
          owner = "CalcProgrammer1";
          repo = "OpenRGB";
          inherit rev;
          fetchSubmodules = true;
          hash = "sha256-mpDcFWB41wfjHkMydvJaQlkDXuMMUE1A3F1PO5mweeE=";
        };

        # Patches do nixpkgs podem não aplicar no master atual.
        patches = [ ];

        # Evita falhas de substituição herdadas do nixpkgs (scripts mudam no master).
        postPatch = ''
          patchShebangs scripts/build-udev-rules.sh
        '';

        postInstall = (old.postInstall or "") + ''
          if [ -d "$out/lib/udev/rules.d" ]; then
            for f in "$out"/lib/udev/rules.d/*.rules; do
              [ -e "$f" ] || continue
              substituteInPlace "$f" --replace-warn "/usr/bin/env" "${prev.coreutils}/bin/env"
            done
          fi
        '';
      }
    );
  };

  # Workaround (DrKonqi): evita falha na coleta de backtrace.
  #
  # O que é
  # - Um override do `kdePackages.drkonqi` para tolerar módulos sem Build-ID no core.
  #
  # Por quê
  # - Em alguns cores (Qt/Wayland/X11), pode existir mapeamento ELF sem Build-ID
  #   (ex.: libxcb-damage). O DrKonqi abortava a coleta por causa disso.
  #
  # Como
  # - Ajusta `src/data/gdb_preamble/preamble.py` no `postPatch` para ignorar
  #   `NoBuildIdException` durante `resolve_modules()`.
  #
  # Riscos
  # - Se o upstream mudar o trecho alvo, o build falha com mensagem explícita,
  #   evitando aplicar uma alteração incorreta silenciosamente.
  drkonqi-ignore-missing-buildid = final: prev: {
    kdePackages = prev.kdePackages.overrideScope (
      kfinal: kprev: {
        drkonqi = kprev.drkonqi.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.python3 ];
          postPatch = (old.postPatch or "") + ''
                      p="src/data/gdb_preamble/preamble.py"
                      if [ -f "$p" ]; then
                        ${prev.python3}/bin/python - <<'PY'
            from pathlib import Path

            path = Path("src/data/gdb_preamble/preamble.py")
            txt = path.read_text(encoding="utf-8")

            old = (
                "    for line in output.splitlines():\n"
                "        image = CoreImage(line)\n"
                "        if image.valid:\n"
                "            core_images.append(image)\n"
            )

            new = (
                "    for line in output.splitlines():\n"
                "        try:\n"
                "            image = CoreImage(line)\n"
                "        except NoBuildIdException:\n"
                "            # Alguns mapeamentos ELF no core podem não ter Build-ID.\n"
                "            # Não abortar a geração do backtrace por isso.\n"
                "            continue\n"
                "        if image.valid:\n"
                "            core_images.append(image)\n"
            )

            if old not in txt:
                raise SystemExit("drkonqi-ignore-missing-buildid: snippet não encontrado; o upstream mudou")

            path.write_text(txt.replace(old, new, 1), encoding="utf-8")
            PY
                      fi
          '';
        });
      }
    );
  };

  # xeus-cling: workaround
  #
  # Por quê
  # - No nixpkgs unstable atual, o xeus-cling 0.15.3 está falhando no check/installCheck
  #   ao executar notebook via papermill (kernel morre com SIGSEGV).
  # - Isso quebra `home-manager switch` mesmo quando o kernel C++ é opcional.
  #
  # Como
  # - Desativa checks do derivation. O runtime ainda pode ser usado interativamente.
  #
  # Riscos
  # - Mascara regressões do upstream. Remover quando nixpkgs corrigir.
  xeus-cling-no-checks = _final: prev: {
    xeus-cling = prev.xeus-cling.overrideAttrs (_old: {
      doCheck = false;
      doInstallCheck = false;
    });
  };

  # python312: stub de docs
  #
  # Por quê
  # - Em alguns pins do nixpkgs, o derivation de docs do CPython (python3.12-*-doc)
  #   pode falhar no buildSphinxPhase por bug de docutils/sphinx.
  # - Isso não impacta runtime do Python, mas bloqueia `nh os switch`.
  #
  # Quando remover
  # - Quando o build de documentação do Python 3.12 voltar a passar no pin usado aqui.
  #
  # Como
  # - Substitui `python312.passthru.doc` por um pacote vazio (auditável), evitando
  #   compilar a documentação.
  #
  # Riscos
  # - Remove a documentação offline do Python 3.12 do sistema.
  python312-docs-stub = final: prev: {
    python312 = prev.python312.overrideAttrs (old: {
      passthru = (old.passthru or { }) // {
        doc = prev.stdenvNoCC.mkDerivation {
          pname = "python3.12-doc";
          version = (old.version or "unknown");
          dontUnpack = true;
          installPhase = ''
            mkdir -p "$out/share/doc/python3.12"
            cat > "$out/share/doc/python3.12/README.txt" <<'EOF'
            Python 3.12 documentation build disabled in this flake.
            This is a stub output to avoid build failures in sphinx/docutils.
            EOF
          '';
        };
      };
    });
  };

  # ATLauncher: API workaround + bundled Java runtime libs
  #
  # Por quê
  # - O user-agent detalhado usado nas chamadas para api.atlauncher.com está
  #   recebendo HTTP 403 do Cloudflare, o que quebra News e resolução de
  #   loaders via GraphQL (ex.: Fabric).
  # - O runtime Java baixado pelo próprio launcher (ex.: java-runtime-gamma)
  #   precisa de bibliotecas X11/AWT extras no NixOS para mods/clientes que
  #   inicializam AWT/ImageIO (ex.: FancyMenu, Polymer, screenshot tools).
  #
  # Como
  # - Aplica um patch pequeno para reutilizar o user-agent simples do launcher
  #   também nas chamadas internas de API.
  # - Expõe as libs nativas extras via `LD_LIBRARY_PATH` para que o processo
  #   do launcher e o Java do Minecraft herdem um ambiente compatível.
  #
  # Quando remover
  # - Quando o upstream do ATLauncher corrigir o formato aceito pelo endpoint
  #   e/ou passar a exportar esse conjunto de libs automaticamente.
  atlauncher-api-user-agent-workaround = _final: prev: {
    atlauncher =
      (prev.atlauncher.override {
        additionalLibs = with prev; [
          fontconfig
          freetype
          libxext
          libxi
          libxrandr
          libxrender
          libxtst
          zlib
        ];
      }).overrideAttrs
        (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/atlauncher-simplify-api-user-agent.patch
          ];
        });
  };
  openldap-no-checks = _final: prev: {
    pkgsi686Linux = prev.pkgsi686Linux // {
      openldap = prev.pkgsi686Linux.openldap.overrideAttrs (_old: {
        doCheck = false;
        doInstallCheck = false;
      });
    };
  };
}
