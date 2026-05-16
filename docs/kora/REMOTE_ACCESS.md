# Kora Remote Access (SSH Tunneling)

A Kora roda nativamente no **Glacier** (porta local `8787`). Para segurança e simplicidade na Fase 2, ela não expõe a porta publicamente nem via Tailscale de forma direta — o acesso do cliente (**Inspiron**) é feito via túnel SSH autenticado.

## Arquitetura de Túnel

1. A API Kora roda no Glacier escutando apenas em `127.0.0.1:8787`.
2. O usuário no Inspiron executa `kryonix kora tunnel`.
3. O script cria um túnel SSH local repassando a porta `18787` (no Inspiron) para `8787` (no Glacier).
4. A CLI no Inspiron detecta automaticamente que está rodando como cliente e usa `http://127.0.0.1:18787`.

## Como usar

No terminal do Inspiron, abra o túnel:

```bash
kryonix kora tunnel
```

Deixe esse comando rodando. Em outro terminal, use a Kora normalmente:

```bash
kryonix kora health
kryonix kora ask "Resuma meus projetos ativos"
```

## Configuração Avançada

Se o seu host Glacier não for resolvível como `glacier-public` no SSH, você pode configurar o target via variável de ambiente:

```bash
export KRYONIX_GLACIER_SSH_TARGET="rocha@10.0.0.2"
export KRYONIX_GLACIER_SSH_PORT="2224"
kryonix kora tunnel
```

## Por que não expor diretamente no Tailscale?

Embora o Tailscale seja seguro, manter a Kora restrita ao localhost do Glacier adiciona uma camada de defesa em profundidade. O acesso remoto só é possível se o usuário do Inspiron tiver acesso SSH explícito ao Glacier. Além disso, o túnel cria uma relação clara de intencionalidade de uso (o usuário precisa "ligar" o acesso à Kora). Na Fase 3 (Integração Desktop e Background), essa abordagem pode evoluir para um socket persistente.
