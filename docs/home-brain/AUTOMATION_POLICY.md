# Política de Automação e Autonomia

O Kryonix Home Brain foi projetado com um modelo de segurança em camadas para permitir automação sem sacrificar a integridade dos dados.

## Níveis de Autonomia

### Nível 0: Manual (Padrão)
O usuário executa cada comando individualmente. Recomendado para novos usuários ou grandes limpezas.

### Nível 1: Observabilidade Automática
Permitido via timer (systemd) ou cron.
- `scan`, `report`, `plan`, `export-memory --dry-run`.
- **Risco:** Zero. Nenhuma alteração no sistema de arquivos.

### Nível 2: Planejamento Automático
O sistema gera manifestos baseados em sugestões de alta confiança, mas não os aplica.
- `manifest create --safe-only`.
- Envio de notificação ao usuário para revisão.
- **Risco:** Muito baixo. Apenas arquivos de estado são criados.

### Nível 3: Semi-Autônomo com Aprovação
A IA sugere categorias e nomes complexos. O sistema prepara tudo e aguarda o comando `apply --confirm` do usuário.
- **Risco:** Controlado. Exige intervenção humana antes da mutação.

### Nível 4: Autônomo Restrito (Futuro)
Aplicação automática em condições estritas:
- Somente arquivos de confiança máxima (100%).
- Sem conflitos de categoria.
- Sem arquivos sensíveis (PDFs financeiros, chaves, etc).
- Rollback automático em caso de erro.
- **Risco:** Médio. Exige maturidade do motor de taxonomia.

## Proibições Absolutas (Invariantes)

O sistema **NUNCA** deve fazer o seguinte de forma autônoma:
1. **Auto-Delete:** O Kryonix Home Brain não apaga arquivos. Ele apenas move e renomeia.
2. **Limpeza de Duplicatas:** A remoção de arquivos duplicados deve ser sempre uma decisão humana.
3. **Pastas de Sistema:** Jamais aplicar taxonomia em `.config`, `.ssh`, `.gnupg`, `.local` ou diretórios de projetos Git (detectados via `.git`).
4. **Arquivos Críticos:** Não processar backups, imagens de VM ou arquivos acima de 2GB automaticamente.
5. **Aplicação sem Auditoria:** Toda ação deve ser precedida por um manifesto e registrada no log de auditoria.
