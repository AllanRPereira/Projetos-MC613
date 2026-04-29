# Planejamento de testes por simulação — `dram_controller`

## Convenções

- `x`: *don't care* (valor irrelevante para o teste)
- `n`, `n+1`: dado arbitrário usado para checagem
- As descrições de temporização (`tRCD`, `tRP`, `tWR`, *CAS latency*, `tRFC`) devem refletir os parâmetros configurados no controlador.

## Teste 1 — Reset e inicialização (INIT)

Quando `reset = 1`, o controlador deve iniciar a sequência de inicialização da DRAM, mantendo `ready = 0`. Ao finalizar a INIT, `ready` deve voltar para `1`.

### Sequência de ciclos (Teste 1)

```text
Ciclo 1:
  reset = 1
  req   = x
  wEn   = x
  ready = x

Ciclo 2 (PRECHARGE):
  reset = 1
  req   = x
  wEn   = x
  ready = 0

Ciclo 3 (AUTO_REFRESH)

Ciclo 4 (LOAD_MODE_REGISTER)

Ciclo final:
  reset = 0
  req   = x
  wEn   = x
  ready = 1
```

## Teste 2 — Leitura

Quando `req = 1` e `wEn = 0` com `ready = 1`, o controlador deve executar a sequência de leitura respeitando as temporizações.

### Sequência de ciclos (Teste 2)

```text
Ciclo 1:
  req   = 1
  wEn   = 0
  ready = 1
  data  = n

Ciclo 2 (ACTIVATE):
  req   = 0
  wEn   = 0
  ready = 0
  data  = n

Ciclo 3 (espera tRCD)

Ciclo 4 (READ)

Ciclo 5 (espera CAS latency)

Ciclo 6:
  req   = 0
  wEn   = 0
  ready = 0
  data  = n+1

Ciclo 7 (PRECHARGE)

Ciclo 8 (espera tRP)

Ciclo final:
  req   = 0
  wEn   = 0
  ready = 1
  data  = n+1
```

## Teste 3 — Escrita

Quando `req = 1` e `wEn = 1` com `ready = 1`, o controlador deve executar a sequência de escrita corretamente.

### Sequência de ciclos (Teste 3)

```text
Ciclo 1:
  req   = 1
  wEn   = 1
  ready = 1
  data  = n

Ciclo 2 (ACTIVATE):
  req   = 0
  wEn   = 1
  ready = 0
  data  = n

Ciclo 3 (espera tRCD)

Ciclo 4 (WRITE)

Ciclo 5 (espera tWR)

Ciclo 6 (PRECHARGE)

Ciclo 7 (espera tRP)

Ciclo final:
  req   = 0
  wEn   = 0
  ready = 1
  data  = n
```

## Teste 4 — Sinal `ready`

Durante qualquer operação (READ, WRITE, REFRESH), `ready` deve permanecer `0` e só retornar para `1` ao voltar para o estado READY.

## Teste 5 — Refresh periódico

Quando o tempo de refresh é atingido, o controlador deve executar um refresh por um intervalo equivalente a `tRFC`, automaticamente, mesmo sem `req`.

## Teste 6 — Requisição durante operação

Se `ready = 0`, pedidos com `req = 1` devem ser ignorados.

## Teste 7 — Esperas

As esperas de clock (`tRCD`, *CAS latency*, `tRP`, `tWR`) devem ser respeitadas, e nenhuma operação deve ocorrer durante esses intervalos.

## Teste 8 — Escrita seguida de leitura

Simular um fluxo real com uma escrita (`req = 1`, `wEn = 1`, `ready = 1`) seguida de uma leitura (`req = 1`, `wEn = 0`, `ready = 1`).
