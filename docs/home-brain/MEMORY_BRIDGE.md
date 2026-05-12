# Memory Bridge: Integração com Kryonix Brain

O **Memory Bridge** é a ponte que conecta a organização local da sua Home ao grafo de conhecimento global do Kryonix.

## O Comando `export-memory`

Este comando transforma os eventos internos do Home Brain em uma linha do tempo auditável no formato JSONL.

### Fontes de Dados (`--from`)
- `latest-scan`: Metadados de todos os arquivos vistos no último escaneamento.
- `latest-plan`: Sugestões de taxonomia e renomeação.
- `latest-manifest`: Ações que foram preparadas para execução.
- `latest-audit`: Registro histórico do que foi efetivamente alterado.

## Segurança: Zero Content Exposure

Por design, o Memory Bridge segue a política de **Não Leitura de Conteúdo**:
- O sistema exporta caminhos, nomes, tamanhos, hashes e categorias.
- O sistema **NÃO** lê o conteúdo interno dos arquivos.
- O campo `content_exported` é sempre `false`.

## Schema de Eventos (v1)

Cada evento exportado contém 28 campos auditáveis, incluindo:
- `event_id`: Identificador único do evento.
- `source_type`: Origem do dado (scan, plan, etc).
- `file_path`: Caminho absoluto do arquivo.
- `file_hash`: SHA256 do arquivo (identidade digital).
- `category_id`: Categoria atribuída pela taxonomia.
- `taxonomy_score`: Confiança da classificação.
- `action_status`: Resultado da operação (success, failed, none).

## Uso Futuro
Os arquivos `.jsonl` gerados serão ingeridos pelo `kryonix-brain-api` no host **Glacier**, permitindo que você pergunte ao seu Cérebro IA:
> "Onde eu salvei o comprovante do banco que baixei na semana passada?"
> "Quais arquivos foram movidos para a pasta de estudos ontem?"
