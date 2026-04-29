# Planejamento de testes por simulação — `dram_iface`

## Convenções

- `x`: *don't care* (valor irrelevante para o teste)
- `n`, `n+1`: valores arbitrários para checagem

## Teste 1 — Reset

Quando as entradas `reset = 1` e `ready = 1`, as saídas `HEX` e `address` devem ser apagadas, e `req`, `wEn` e `ready` devem ser forçadas para `0`. Após esse ciclo, `reset` deve voltar para `0` e `ready` deve voltar para `1`.

### Sequência de ciclos (Teste 1)

```text
Ciclo 1:
reset   = 1
HEX     = n
address = n
req     = x
wEn     = x
ready   = 1

Ciclo 2:
reset   = 1
HEX     = -
address = -
req     = 0
wEn     = 0
ready   = 0

Ciclo final:
reset   = 0
HEX     = -
address = -
req     = 0
wEn     = 0
ready   = 1
```

## Teste 2 — Leitura automática

Quando algum switch `SW` é alterado (`n -> n+1`) e `ready = 1`, `wEn` e `ready` devem ir para `0`, `req` deve ir para `1` e as saídas `HEX` e `address` devem atualizar apropriadamente (`n -> n+1`). Após o ciclo, `ready = 1` e `req = 0`.

### Sequência de ciclos (Teste 2)

```text
Ciclo 1:
SW      = n+1
wEn     = x
ready   = 1
req     = x
HEX     = n
address = n

Ciclo 2:
SW      = n+1
wEn     = 0
ready   = 0
req     = 1
HEX     = n+1
address = n+1

Ciclo final:
SW      = n+1
wEn     = 0
ready   = 1
req     = 0
HEX     = n+1
address = n+1
```

## Teste 3 — Espera de operação

Quando algum input é alterado durante `ready = 0`, nenhuma saída deve ser alterada.

## Teste 4 — Escrita

Quando `ready = 1` e `wEn = 1`, uma operação de escrita é feita com o valor nos switches, e então uma leitura com `HEX0` do valor armazenado.

### Sequência de ciclos (Teste 4)

```text
Ciclo 1:
ready = 1
wEn   = 1
SW    = n
req   = x
HEX0  = n

Ciclo 2:
ready = 0
wEn   = 1
SW    = n
req   = 1
HEX0  = n

Ciclo final:
ready = 1
wEn   = 0
SW    = n
req   = 0
HEX0  = n+1
```

## Teste 5 — Espera de clocks

Apertar keys de reset e write e mudar switches simultaneamente não deve ter efeito, respeitando o tempo de clock necessário entre operações.
