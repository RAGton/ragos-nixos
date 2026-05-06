# =============================================================================
# Módulo: kryonix.services.kryonix-state
#
# O que é:
# - Cria a estrutura de diretórios do layout de estado canônico em
#   /var/lib/kryonix via systemd.tmpfiles.
#
# Por quê:
# - Garante que os caminhos para o Kryonix Brain, RAG, CAG, Neo4j, reasoning,
#   e pipelines de ingestão estejam criados declarativamente com as permissões corretas.
# =============================================================================
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kryonix.services.brain;
in
{
  config = mkIf (cfg.enable && cfg.role == "server") {
    systemd.tmpfiles.rules = [
      "d /home/storage/kryonix 0755 ${cfg.user} ${cfg.group} - -"
      "L /var/lib/kryonix - - - - /home/storage/kryonix"
      "d /home/storage/kryonix/brain 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/lightrag 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/lightrag/storage 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/lightrag/cache 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/lightrag/snapshots 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/neo4j 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/neo4j/data 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/neo4j/logs 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/neo4j/import 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/neo4j/plugins 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/rag 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/rag/manifests 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/rag/chunks 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/rag/embeddings 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/rag/rerank 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/rag/cache 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/cag 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/cag/context-cache 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/cag/prompt-cache 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/cag/invalidation 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/reasoning 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/reasoning/traces 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/reasoning/reports 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/ingest 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/ingest/queue 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/ingest/processed 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/ingest/failed 0755 ${cfg.user} ${cfg.group} - -"
      "d /home/storage/kryonix/brain/ingest/quarantine 0755 ${cfg.user} ${cfg.group} - -"
      "d /var/log/kryonix 0755 ${cfg.user} ${cfg.group} - -"
      "d /run/kryonix 0755 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
