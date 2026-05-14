# Troubleshooting

Status: Implementado (playbook base)

## Resumo
Metodologia oficial para identificar, classificar e corrigir erros sem mascará-los.

## Método
1. Capturar a mensagem exata.
2. Identificar comando/módulo que gerou o erro.
3. Classificar: novo, antigo, ou ambiente.
4. Corrigir, testar novamente e comunicar.

## Problemas conhecidos (resumo)
- Build do Inspiron puxando cadeia pesada (`deno`, `rusty-v8`).
- Caelestia com `postPatch` inválido.
- Erros de DBus/sessão gráfica.
- `bwrap: Can't chdir to /etc/kryonix`.

## Quando usar
Quando uma validação falhar ou um serviço não subir.

## Comandos relevantes
```sh
systemctl --user status dbus.service --no-pager
journalctl --user -b --no-pager -n 200
nix why-depends .#nixosConfigurations.inspiron.config.system.build.toplevel <drv>
```

## Riscos
- Aplicar workarounds sem diagnóstico.
- Silenciar erros críticos com `|| true`.

## Links relacionados
- [Testes e Validação](Testes-e-Validacao)
- [Operações](Operacoes)
- [Segurança](Seguranca)
