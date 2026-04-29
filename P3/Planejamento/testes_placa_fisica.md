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

1. **Teste de reset durante a execução (robustez)**

- Repetir os testes acima pressionando **reset** em diferentes momentos (por exemplo: durante escrita, entre escrita/leitura e durante leitura).

Resultados esperados:

- O sistema deve retornar ao estado de inicialização de forma consistente.
- O comportamento após reset deve estar de acordo com a lógica do projeto (por exemplo: reinicialização do fluxo de controle e limpeza/invalidação dos dados).

Critério de aprovação: após reset, o sistema não pode travar, e deve voltar a operar normalmente em novas leituras/escritas.

## Observações e casos de borda

- Tentar mudanças rápidas e contínuas nos comandos (switches/keys) para validar transições de estado e confirmar que o `dram_iface` respeita os tempos de espera e atrasos da memória.
- Verificar o comportamento de *debouncing*: evitar manter a tecla pressionada continuamente e observar se oscilações mecânicas geram múltiplos comandos indesejados.
- Confirmar a conversão correta do valor armazenado para a representação nos displays de 7 segmentos.
