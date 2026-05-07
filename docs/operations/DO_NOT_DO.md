# Práticas Proibidas — O que NÃO fazer no Kryonix

Este documento registra políticas de segurança, estabilidade e boas práticas operacionais que nunca devem ser violadas por operadores humanos ou agentes de IA.

---

## Home Manager e Builds

- Não rodar `kryonix home` novamente sem antes passar `nh home build`.
- Não commitar `flake.lock` se ele foi alterado acidentalmente por `--update`.
- Não resolver erro de vendoring Rust com hash inventado.
