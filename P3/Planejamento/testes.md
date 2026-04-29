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

# Testes da aplicação na placa (controlador DRAM)

O objetivo dos testes na placa é confirmar, na placa, o mesmo comportamento validado na simulação. Nesta etapa, o foco é o módulo `dram_iface`, responsável por intermediar a comunicação com o controlador de DRAM e expor comandos via *switches*, *keys* e displays de 7 segmentos.

## O que observar durante os testes

- **Endereço em acesso**: indicado nos displays (HEX4/HEX5, conforme mapeamento do projeto).
- **Dado escrito**: mostrado em HEX0.
- **Dado lido após a operação**: mostrado em HEX1.

> Observação: a nomenclatura e o mapeamento exato (quais bits vão para cada HEX) dependem da implementação do `dram_iface`. Os itens abaixo assumem o mapeamento descrito no projeto.

## Procedimento de teste na placa

1. **Escrita e leitura em um endereço conhecido**

- Configurar os switches para `SW[9:0] = "1000000001"`.
- Com essa configuração, o sistema deve acessar o endereço `0x2000000` e escrever o dado `0b0001` (barramento de 8 bits).

Resultados esperados:

- **HEX0** exibe `1` (dado escrito).
- Ao final da escrita (e após a transição para o estado de leitura), **HEX1** exibe `1` (dado lido de volta).
- **HEX4** e **HEX5** exibem as partes baixa e alta do endereço, respectivamente (4 bits menos significativos em HEX4 e os 3 bits restantes em HEX5, conforme especificação).

Critério de aprovação: os valores exibidos devem ser estáveis e coerentes com o endereço e o dado configurados.

1. **Escritas sequenciais com dados incrementais (varredura simples)**

- Escrever valores incrementais `1, 2, 3, 4, ..., 16` (com `SW[3:0]` habilitados, conforme o projeto).
- Para cada valor, incrementar o endereço em 1 na faixa `Address[23:20]`, de modo a preencher posições consecutivas para posterior leitura.

Resultados esperados:

- Após cada escrita, **HEX0** deve refletir o valor recém-escrito.
- Após a leitura correspondente, **HEX1** deve refletir o mesmo valor (em hexadecimal).

Critério de aprovação: para cada endereço escrito, a leitura subsequente deve retornar exatamente o dado esperado.

1. **Leitura de retorno (verificação dos dados previamente gravados)**

- Retornar ao endereço inicial (`SW[9:0] = "1000000001"`).
- Realizar apenas leituras, verificando se os dados exibidos correspondem aos valores gravados anteriormente.

Resultados esperados:

- **HEX1** deve exibir os mesmos valores que foram escritos para cada endereço testado.

Critério de aprovação: não deve haver divergência entre o histórico de escrita e as leituras observadas.

1. **Teste de reset durante a execução**

- Repetir os testes acima pressionando **reset** em diferentes momentos (por exemplo: durante escrita, entre escrita/leitura e durante leitura).

Resultados esperados:

- O sistema deve retornar ao estado de inicialização de forma consistente.
- O comportamento após reset deve estar de acordo com a lógica do projeto (por exemplo: reinicialização do fluxo de controle e limpeza/invalidação dos dados).

Critério de aprovação: após reset, o sistema não pode travar, e deve voltar a operar normalmente em novas leituras/escritas.

## Observações e casos de borda

- Tentar mudanças rápidas e contínuas nos comandos (switches/keys) para validar transições de estado e confirmar que o `dram_iface` respeita os tempos de espera e atrasos da memória.
- Verificar o comportamento de *debouncing*: evitar manter a tecla pressionada continuamente e observar se oscilações mecânicas geram múltiplos comandos indesejados.
- Confirmar a conversão correta do valor armazenado para a representação nos displays de 7 segmentos