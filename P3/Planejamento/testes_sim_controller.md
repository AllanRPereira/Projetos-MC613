Planejamento de Testes por Simulação de dram_controller

Teste 1: Reset e Inicialização (INIT)
Quando reset = 1, o controlador deve iniciar o processo de inicialização da DRAM, mantendo ready = 0 e executando a sequência de comandos de INIT. Após finalizar, ready = 1.

Ciclo 1:
reset = 1
req = x
wEn = x
ready = x

Ciclo 2 (PRECHARGE):
reset = 1
req = x
wEn = x
ready = 0

Ciclo 3 (AUTO_REFRESH)

Ciclo 4 (LOAD_MODE_REGISTER)

Ciclo Final:
reset = 0
req = x
wEn = x
ready = 1

Teste 2: Leitura
Quando req = 1 e wEn = 0 com ready = 1, o controlador deve executar a sequência de leitura respeitando temporização.

Ciclo 1:
req = 1
wEn = 0
ready = 1
data = n

Ciclo 2 (ACTIVATE)
req = 0
wEn = 0
ready = 0
data = n

Ciclo 3 (espera tRCD)

Ciclo 4 (READ)

Ciclo 5 (espera CAS latency)

Ciclo 6
req = 0
wEn = 0
ready = 0
data = n+1

Ciclo 7 (PRECHARGE)

Ciclo 8 (espera tRP)

Ciclo Final
req = 0
wEn = 0
ready = 1
data = n+1

Teste 3: Escrita
Quando req = 1 e wEn = 1, o controlador deve executar a sequência de escrita corretamente.

Ciclo 1
req = 1
wEn = 1
ready = 1
data = n

Ciclo 2 (ACTIVATE)
req = 0
wEn = 1
ready = 0
data = n

Ciclo 3 (espera tRCD)

Ciclo 4 (WRITE)

Ciclo 5 (espera TWR)

Ciclo 6 (PRECHARGE)

Ciclo 7 (espera tRP)

Ciclo Final
req = 0
wEn = 0
ready = 1
data = n

Teste 4: Sinal Ready
Durante qualquer operação (READ, WRITE, REFRESH), ready deve permanecer 0. Só retornando para 1 quando retornar ao estado READY.

Teste 5: Refresh Periódico
Quando o tempo de refresh é atingido, o controlador deve executar um refresh ao longo de um tRFC automaticamente, mesmo sem req.

Teste 6: Requisição durante Operação
Se ready = 0, pedidos de req devem ser ignorados.

Teste 7: Esperas
Esperas de clock (tRCD, CAS, tRP, tWR) devem ser respeitadas, e nenhuma operação pode ocorrer ao longo delas.

Teste 8: Escrita e Leitura
Finalmente, simular um fluxo real, com uma operação de escrita (req = 1, wEn = 1, ready = 1) e então uma operação de leitura (req = 1, wEn = 0, ready = 1).