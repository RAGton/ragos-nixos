# WayVNC / Acesso Remoto

Status: Implementado e validado

## Resumo
O acesso remoto gráfico ao Glacier usa WayVNC preso ao localhost e túnel SSH no Inspiron.

## Topologia
```
[ Inspiron ] 127.0.0.1:5901 --SSH--> [ Glacier ] 127.0.0.1:5900
```

## Quando usar
Para acessar o desktop do Glacier sem expor VNC publicamente.

## Comandos relevantes
```sh
kryonix remote vnc status
kryonix remote vnc start
kryonix remote vnc stop
```

## Riscos
- Expor `0.0.0.0:5900` no Glacier.
- Túnel SSH sem autenticação adequada.

## Links relacionados
- [Operações](Operacoes)
- [Segurança](Seguranca)
- [Glacier](Glacier)
