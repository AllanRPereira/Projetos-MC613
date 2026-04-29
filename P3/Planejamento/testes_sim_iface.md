Planejamento de Testes por Simulação de dram_iface

Teste 1: Reset
Quando a entrada reset e ready são 1, as saídas HEX e address devem ser apagadas, req, wEn e ready devem ser 0. Após esse ciclo, reset deve ser 0 e ready deve ser 1.

Ciclo 1:
reset = 1
HEX = n
address = n
req = x
wEn = x
ready = 1

Ciclo 2:
reset = 1
HEX = -
address = -
req = 0
wEn = 0
ready = 0

Ciclo Final:
reset = 0
HEX = -
address = -
req = 0
wEn = 0
ready = 1

Teste 2: Leitura Automática
Quando algum switch SW é alterado(n -> n+1) e ready=1, wEn e ready devem ser 0, req deve ser 1 e as saidas HEX e address devem ser alteradas apropriadamente (n -> n+1). Após o ciclo, ready=1 e req=0.

Ciclo 1:
SW = n+1
wEn = x
ready = 1
req = x
HEX = n
address = n

Ciclo 2:
SW = n+1
wEn = 0
ready = 0
req = 1
HEX = n+1
address = n+1

Ciclo Final:
SW = n+1
wEn = 0
ready = 1
req = 0
HEX = n+1
address = n+1

Teste 3: Espera de Operação
Quando algum input é alterado durante ready=0, nenhuma saida deve ser alterada.

Teste 4: Escrita
Quando ready e wEn são 1, uma operação de escrita é feita com o valor nos switches, e então uma leitura com HEX0 do valor armazenado.

Ciclo 1:
ready = 1
wEn = 1
SW = n
req = x
HEX0 = n

Ciclo 2:
ready = 0
wEn = 1
SW = n
req = 1
HEX0 = n

Ciclo Final:
ready = 1
wEn = 0
SW = n
req = 0
HEX0 = n+1

Teste 5: Espera de Clocks
Apertar Keys de reset e write e mudar switches simultâneamente não deve ter efeito, reconhecendo o tempo de clock necessário entre operações.