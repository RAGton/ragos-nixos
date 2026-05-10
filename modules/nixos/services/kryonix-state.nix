# =============================================================================
# Módulo: kryonix.services.state
#
# O que é:
# - Cria a estrutura de diretórios do layout de estado canônico em
#   /var/lib/kryonix via systemd.tmpfiles.
#
# Por quê:
# - Garante que os caminhos para o Kryonix Brain, RAG, CAG, Neo4j, reasoning,
#   e pipelines de ingestão estejam criados declarativamente com as permissões corretas.
# - Suporta o novo layout Btrfs manual sem criar links simbólicos frágeis por padrão.
# =============================================================================
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kryonix.services.state;
  brainCfg = config.kryonix.services.brain;
  stateDir = if cfg.legacySymlink.enable then "/home/storage/kryonix" else "/var/lib/kryonix";
in
{
  options.kryonix.services.state = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Habilita o gerenciamento do estado canônico do Kryonix.";
    };

    legacySymlink = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Se true, cria /var/lib/kryonix como link simbólico para /home/storage/kryonix (padrão legado).
          Se false, cria /var/lib/kryonix como diretório normal para receber o mount real do Btrfs.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && brainCfg.enable && brainCfg.role == "server") {
    assertions = [
      {
        assertion = !(cfg.legacySymlink.enable && (config.fileSystems ? "/var/lib/kryonix"));
        message = ''
          kryonix.services.state.legacySymlink.enable=true não pode ser usado quando /var/lib/kryonix é um mount real.
          Desative o legacySymlink ou remova o mount /var/lib/kryonix em fileSystems.
        '';
      }
    ];

    systemd.tmpfiles.rules = [
      "d /home/storage 0755 root root - -"
    ]
    ++ (
      if cfg.legacySymlink.enable then
        [
          "d /home/storage/kryonix 0755 root root - -"
          "L /var/lib/kryonix - - - - /home/storage/kryonix"
        ]
      else
        [
          "d /var/lib/kryonix 0755 root root - -"
        ]
    )
    ++ [
      "d ${stateDir}/brain 0755 root root - -"
      "f ${stateDir}/brain/graph_audit.jsonl 0640 ${brainCfg.user} ${brainCfg.group} - -"
      "z ${stateDir}/brain/graph_audit.jsonl 0640 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/graph_manifests 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/storage 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/cache 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/snapshots 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/neo4j 0770 neo4j neo4j - -"
      "d ${stateDir}/brain/neo4j/data 0770 neo4j neo4j - -"
      "d ${stateDir}/brain/neo4j/logs 0770 neo4j neo4j - -"
      "d ${stateDir}/brain/neo4j/import 0770 neo4j neo4j - -"
      "d ${stateDir}/brain/neo4j/plugins 0770 neo4j neo4j - -"
      "d ${stateDir}/brain/neo4j/conf 0770 neo4j neo4j - -"
      "d ${stateDir}/brain/rag 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/rag/manifests 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/rag/chunks 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/rag/embeddings 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/rag/rerank 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/rag/cache 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/cag 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/cag/context-cache 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/cag/prompt-cache 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/cag/invalidation 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/reasoning 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/reasoning/traces 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/reasoning/reports 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/ingest 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/ingest/queue 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/ingest/processed 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/ingest/failed 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/brain/ingest/quarantine 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d ${stateDir}/ollama 0755 ollama ollama - -"
      "d ${stateDir}/ollama/models 0755 ollama ollama - -"
      "d /var/log/kryonix 0755 ${brainCfg.user} ${brainCfg.group} - -"
      "d /run/kryonix 0755 ${brainCfg.user} ${brainCfg.group} - -"
    ];
  };
}
