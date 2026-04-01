
### Testes por Simulação

A simulação deve ser feita de forma modular para garantir que a lógica esteja correta para cada módulo individualmente:

* **FSM**
    * **Cenário de Início:** Forçar `sig_confirmar` e verificar se o estado muda de `iniciar` para `movimento`.
    * **Ciclo de Colisão:** Em `movimento`, acionar `sig_batida` e verificar a transição para `bate_parede` e, após o tempo simulado de `sig_2s`, a transição para `fim_jogo`.
    * **Principais objetivos:** Testar o que acontece se `sig_fruta` e `sig_mordida` ocorrerem no mesmo ciclo de clock para garantir que a FSM não trave em estado indefinido.

* **PPU e VGA:**
    * **Temporização VGA:** Verificar se os sinais *HSYNC* e *VSYNC* seguem os padrões de temporização para 640x480 @ 60Hz.
    * **Exibição dos Tiles:** Simular as coordenadas $(x, y)$ e verificar se o sinal de saída RGB muda de cor corretamente ao atingir a área onde a "fruta" ou a "cobra" deveriam estar posicionadas.

* **Integração Incremental:**
    * Conectar a **Máquina de Controle** à **FSM**. Verificar se comandos de movimentação (cima, baixo, etc.) atualizam corretamente os registradores de posição da cobra que a PPU utiliza para desenhar.

---

### Testes na Placa

1.  **Etapa 1:** Carregar um código que exiba apenas barras de cores ou uma tela estática. Isso verifica a conexão com o monitor e os tempos do módulo VGA.
2.  **Etapa 2:** Utilizar chaves (*switches*) da placa para alterar o background do tela antes de iniciar o jogo.
3.  **Etapa 3:** Mapear os estados da sua FSM (como `iniciar`, `movimento`, `fim_jogo`) nos displays de 7 segmentos ou LEDs da placa, pressionando os botões e verificando se o estados transitam adequadamente
4.  **Etapa 4:** Integrar a FSM com a movimentação e iniciar a execução do jogo em todos as suas etapas.

---

### 3. Descrição da Aplicação Visual (Jogo da Cobrinha)

A aplicação será a seguinte:

* **Área de Jogo:** Área total da tela onde a cobra pode se mover
* **Elementos Gráficos:**
    * **Cobra:** Composta por tiles (quadrados), em que seus elementos são de unidades de 8x8,
    * **Fruta:** Um tile de cor distinta que surge em coordenadas aleatórias não preenchidas pela cobra.
    * **Placar:** Exibição nos displays de 7 segmentos da placa.
* **Lógica do Jogo:**
    * **Tela de Início:** Fundo de uma cor específica que pode ser alterada pelos swtiches, aguardando o pressionando da KEY[0]
    * **Jogabilidade:** Cobrinha se move na tela de modo automática com base na direção definida pelo usuário. As frutas que surgem podem ser comidas para aumentar o tamanho da cobra. Você perde o jogo quando há impacto na parede ou quando você atinge uma parte do corpo. Você ganha quando atinge o tamanho máximo da cobra.
---

### 4. Entregáveis

| Entregável | Descrição |
| :--- | :--- |
| **Código Verilog** | Módulos da FSM, PPU e VGA finalizados. |
| **Relatório de Simulação** | Prints do *Waveform* mostrando a transição de estados da FSM conforme a tabela fornecida. |
| **Demonstração VGA** | A placa deve ser capaz de exibir, no mínimo, a tela de início do jogo ou uma grade estática no monitor. |
| **Diagrama de Blocos Atualizado** | Mostrando como os sinais `sig_fruta`, `sig_batida`, etc., são gerados pela lógica de colisão e entregues à FSM. |
