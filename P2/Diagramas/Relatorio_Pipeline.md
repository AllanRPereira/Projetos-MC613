# Relatório do Pipeline de Execução do Jogo da Cobrinha

## Visão geral

Este projeto implementa um jogo da cobrinha em FPGA com saída VGA, usando uma arquitetura em pipeline composta por:

1. entrada de botões e chaves,
2. máquina de estados do jogo,
3. máquina de controle,
4. lógica de movimento/crescimento da cobra,
5. controlador de fruta,
6. OAM de sprites,
7. ROMs de sprites, paleta e background,
8. composição final de cor,
9. geração do sinal VGA.

O módulo central do sistema é `ppu_top.v`, que integra todos os blocos e organiza os pulsos de tempo usados pelo jogo.

## Fluxo de execução

### 1. Clock, reset e entradas

- `CLOCK_50` alimenta o PLL.
- O PLL gera `pixel_clk`, que é o clock principal de todo o jogo.
- `KEY[0]` atua como reset global.
- `KEY[1]` confirma o início ou reinício do jogo.
- `KEY[2]` e `KEY[3]` são usados para alterar a direção da cobra.
- `SW[3:1]` altera o background de forma manual.

### 2. Geração de pulsos de tempo

O `ppu_top.v` conta ciclos de `pixel_clk` e produz pulsos derivados:

- `pulso_5ms`: base temporal do movimento.
- `pulso_100ms`: usado para amostragem de botões.
- `pulso_2s`: usado em transições de estados mais lentas.
- `pulso_movimento`: determina quando a cobra deve avançar um tile.

Esses pulsos desacoplam a lógica do jogo do clock de vídeo, evitando que a movimentação ocorra em velocidade excessiva.

### 3. Máquina de estados

A `maquina_estados.v` define o estado global do jogo:

- `INICIAR`: espera confirmação do jogador.
- `MOVIMENTO`: estado normal do jogo.
- `AUMENTAR_VEL`: pausa breve ao aumentar a velocidade.
- `COME_FRUTA`: estado transitório após comer fruta.
- `SE_MORDEU`: estado de derrota por auto-colisão.
- `BATE_PAREDE`: estado de derrota por colisão com a borda.
- `VITORIA`: estado de vitória.
- `FIM_JOGO`: tela final, aguardando nova confirmação.

A FSM recebe sinais de ocorrência do jogo, como:

- fruta comida,
- mordida no corpo,
- colisão na parede,
- vitória,
- confirmação do botão.

### 4. Máquina de controle

A `maquina_controle.v` transforma entradas humanas e sinais internos do jogo em comandos auxiliares:

- detecta pulsos de botão,
- atualiza direção atual,
- controla quantidade de frutas comidas,
- controla pontuação,
- eleva a velocidade a cada bloco de frutas definido.

Ela também gera sinais usados pela FSM, como `sig_confirmar`, `sig_dir`, `sig_vel` e os sinais de colisão/fruit event.

### 5. Lógica da cobra

O módulo `cobra_crescimento.v` é responsável por:

- armazenar o corpo da cobra em um buffer circular,
- manter um bitmap de ocupação para detecção rápida de colisão,
- calcular a próxima posição da cabeça,
- decidir se haverá crescimento,
- atualizar cabeça, corpo e cauda na OAM,
- sinalizar colisão com parede, corpo ou vitória.

O comportamento é dividido em fases de escrita para evitar efeitos visuais incorretos:

1. captura da posição atual,
2. atualização do tile antigo da cabeça,
3. limpeza da cauda quando necessário,
4. escrita da nova cabeça.

Essa separação é importante porque a leitura da OAM acontece continuamente durante o desenho da tela, então a atualização precisa ocorrer de forma ordenada.

### 6. Controlador de fruta

O `fruta_controlador.v` cria uma nova fruta em um tile livre e garante que a fruta antiga seja removida da OAM antes da geração da próxima.

O fluxo é:

1. gerar uma semente inicial,
2. calcular o endereço candidato,
3. consultar a OAM combinacionalmente,
4. escolher um tile vazio,
5. escrever o sprite da fruta,
6. ao comer a fruta, limpar a posição anterior e procurar uma nova.

### 7. OAM de sprites

O `ram_oam.v` funciona como a memória visual do jogo.

Cada tile da tela possui um ID de sprite associado:

- `0`: vazio,
- `1`: cabeça da cobra,
- `3`: corpo da cobra,
- `2`: fruta.

A OAM possui:

- leitura direta para o pixel corrente,
- leitura auxiliar para busca de espaço livre,
- escrita compartilhada entre cobra e fruta,
- limpeza sequencial completa no reset e ao entrar em colisão/fim.

### 8. ROM de sprites e paleta

As ROMs definem a aparência dos elementos:

- `rom_sprite.v`: escolhe os quadrantes da imagem do sprite.
- `rom_palette.v`: converte índices em RGB.
- `rom_background.v`: define a cor do fundo do tile.

Na etapa de vídeo, o `interceptor.v` escolhe qual quadrante do sprite está ativo em cada pixel e o `color_selector.v` decide se o pixel será do sprite ou do background.

### 9. Saída VGA

O módulo `VGA.v` gera:

- contadores horizontais e verticais,
- `VGA_HS` e `VGA_VS`,
- indicação de área ativa,
- `VGA_R`, `VGA_G`, `VGA_B`,
- `VGA_CLK`.

### 10. Composição final da imagem

O `ppu_top.v` combina tudo assim:

1. o estado do jogo vem da FSM,
2. o controle converte eventos em direção/pontuação/velocidade,
3. a cobra escreve suas mudanças na OAM,
4. a fruta mantém um único sprite válido por vez,
5. a OAM fornece o ID do sprite do tile atual,
6. o `rom_sprite` traduz o ID em paleta de quadrantes,
7. o `interceptor` escolhe a cor do quadrante correto,
8. o `color_selector` mistura sprite e background,
9. o módulo VGA entrega a imagem final ao monitor.

## Pipeline resumido

```text
Botões/Chaves -> ppu_top -> FSM -> Controle -> Cobra/Fruta -> OAM -> ROMs -> Cor final -> VGA
```

## Observações importantes de implementação

- O movimento da cobra não é feito em cada ciclo do clock de vídeo; ele usa pulsos mais lentos para parecer fluido.
- A OAM precisa ser limpa de forma explícita para não manter sprites residuais após reset ou colisão.
- A fruta deve existir apenas em um endereço ativo; se a posição anterior não for removida, surgem várias frutas simultâneas.
- A atualização da cobra precisa respeitar fases de escrita para que a cabeça, o corpo e a cauda não deixem rastros.

## O que foi validado

- integração completa dos módulos em `ppu_top.v`;
- leitura correta de direção e confirmação;
- geração de frutas sem duplicação;
- limpeza da OAM no reset e em fim de jogo;
- movimento com fluidez adequada;
- exibição correta de cobra, fruta e background.

## Conclusão

O projeto foi estruturado para separar claramente a lógica de jogo da lógica de vídeo. Isso facilita a manutenção, a explicação para o grupo e a depuração de problemas de hardware, porque cada bloco possui uma responsabilidade bem definida.
