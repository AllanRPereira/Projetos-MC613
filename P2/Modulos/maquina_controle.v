module maquina_controle (
    input wire clk,
    input wire reset,
    input wire clk_5ms,
    input wire clk_100ms,
    input wire clk_2s,
    input wire botao_confirmar,
    input wire botao_1,
    input wire botao_2,

    // Vindo da máquina de estados
    input wire [3:0] estado_atual,

    // Dados que virão do módulo de crescimento
    input wire comeu_fruta,
    input wire bateu_corpo,
    input wire bateu_parede,
    input wire cobra_cheia,

    // Sinais para a máquina de estados mudar de estado
    output wire sig_fruta,
    output wire sig_mordida,
    output wire sig_5ms,
    output wire sig_2s,
    output wire sig_batida,
    output wire sig_confirmar,
    output wire sig_vel,
    output wire sig_dir,
    output wire sig_vit,

    // Saída para movimentação da cobra e tamanho dela na tela
    output reg [1:0] direcao_atual,
    output reg [7:0] frutas_comidas,
    output reg [2:0] nivel_velocidade,
    output reg [9:0] pontos
);
    // Parâmetros constantes que identificam os estados
    localparam INICIAR      = 4'd0;
    localparam MOVIMENTO    = 4'd1;
    localparam AUMENTAR_VEL = 4'd2;
    localparam COME_FRUTA   = 4'd3;
    localparam MUDAR_DIR    = 4'd4;
    localparam SE_MORDEU    = 4'd5;
    localparam BATE_PAREDE  = 4'd6;
    localparam VITORIA      = 4'd7;
    localparam FIM_JOGO     = 4'd8;

    // Quantidade de frutas para aumentar de tamanho, e o quanto aumenta de velocidade
    localparam FRUTAS_PARA_AUMENTO = 8'd4;
    localparam NIVEL_MAXIMO        = 3'd5;


    // Parâmetros de direção do movimento
    localparam ESQ   = 2'd0;
    localparam DIR   = 2'd1;
    localparam CIMA  = 2'd2;
    localparam BAIXO = 2'd3;

    // Registradores para armazenar as informações dos botões apertados
    reg botao_confirmar_d;
    reg botao_1_d;
    reg botao_2_d;

    reg sig_vel_r;

    wire confirmar_pulse;
    wire botao_esq_pulse;
    wire botao_dir_pulse;
    wire mudar_dir_pulse;

    // Link com os valores dos registrador para mudar apenas quando necessário
    assign confirmar_pulse = clk_100ms & botao_confirmar & ~botao_confirmar_d;
    assign botao_esq_pulse = clk_100ms & botao_1 & ~botao_1_d;
    assign botao_dir_pulse = clk_100ms & botao_2 & ~botao_2_d;
    assign mudar_dir_pulse = botao_esq_pulse | botao_dir_pulse;

    assign sig_confirmar = confirmar_pulse;
    assign sig_5ms = clk_5ms;
    assign sig_2s = clk_2s;

    // Sinais que são revelantes e devem mudar apenas no estado de movimento
    assign sig_fruta = (estado_atual == MOVIMENTO) && comeu_fruta;
    assign sig_mordida = (estado_atual == MOVIMENTO) && bateu_corpo;
    assign sig_batida = (estado_atual == MOVIMENTO) && bateu_parede;
    assign sig_vit = (estado_atual == MOVIMENTO) && cobra_cheia;
    assign sig_dir = (estado_atual == MOVIMENTO) && mudar_dir_pulse;
    assign sig_vel = sig_vel_r;

    // Função que garante o giro correto para a esquerda, já que muda dependendo do movimento
    // atual da cobra
    function [1:0] gira_esquerda;
        input [1:0] direcao;    // Entrada
        begin
            case (direcao)
                ESQ:   gira_esquerda = BAIXO;
                BAIXO: gira_esquerda = DIR;
                DIR:   gira_esquerda = CIMA;
                CIMA:  gira_esquerda = ESQ;
                default: gira_esquerda = ESQ;
            endcase
        end
    endfunction

    // Analogamente para um giro para a direita
    function [1:0] gira_direita;
        input [1:0] direcao;    // Entrada
        begin
            case (direcao)
                ESQ:   gira_direita = CIMA;
                CIMA:  gira_direita = DIR;
                DIR:   gira_direita = BAIXO;
                BAIXO: gira_direita = ESQ;
                default: gira_direita = ESQ;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            // Dados gerais setados para 0

            botao_confirmar_d <= 1'b0;
            botao_1_d <= 1'b0;
            botao_2_d <= 1'b0;
            direcao_atual <= DIR;
            frutas_comidas <= 8'd0;
            nivel_velocidade <= 3'd0;
            pontos <= 10'd0;
            sig_vel_r <= 1'b0;

        end else begin

            sig_vel_r <= 1'b0;

            // Avaliar apenas a cada 100ms em subidas específicas
            if (clk_100ms) begin
                botao_confirmar_d <= botao_confirmar;
                botao_1_d <= botao_1;
                botao_2_d <= botao_2;
            end

            case (estado_atual)
                INICIAR: begin
                    // Estado inicial da cobrinha
                    direcao_atual <= DIR;
                    frutas_comidas <= 8'd0;
                    nivel_velocidade <= 3'd0;
                    pontos <= 10'd0;
                end

                MOVIMENTO: begin
                    // Valor base da velocidade
                    if (nivel_velocidade == 3'd0) begin
                        nivel_velocidade <= 3'd1;
                    end

                    // Giro da cobrinha
                    if (botao_esq_pulse) begin
                        direcao_atual <= gira_esquerda(direcao_atual);
                    end else if (botao_dir_pulse) begin
                        direcao_atual <= gira_direita(direcao_atual);
                    end

                    // Comer fruta e aumentar tamanho
                    if (comeu_fruta) begin
                        frutas_comidas <= frutas_comidas + 8'd1;
                        pontos <= pontos + 10'd2;

                        if (((frutas_comidas + 8'd1) % FRUTAS_PARA_AUMENTO) == 8'd0) begin
                            if (nivel_velocidade < NIVEL_MAXIMO) begin
                                nivel_velocidade <= nivel_velocidade + 3'd1;
                                sig_vel_r <= 1'b1;
                            end
                        end
                    end
                end

                AUMENTAR_VEL: begin
                    // Estado de espera até o temporizador de 2s liberar a volta ao movimento.
                end

                COME_FRUTA: begin
                    // A lógica de crescimento já foi tratada no ciclo em que a fruta foi detectada.
                end

                MUDAR_DIR: begin
                    // O giro é aplicado no estado MOVIMENTO, onde o pulso de botão é gerado.
                end

                SE_MORDEU: begin
                    // Cobrinha sem movimento
                    nivel_velocidade <= 3'd0;
                    if (clk_2s) begin
                        pontos <= pontos;
                    end
                end

                BATE_PAREDE: begin
                    // Cobrinha sem movimento
                    nivel_velocidade <= 3'd0;
                    if (clk_2s) begin
                        pontos <= pontos;
                    end
                end

                VITORIA: begin
                    // Cobrinha sem movimento
                    nivel_velocidade <= 3'd0;
                    if (clk_2s) begin
                        pontos <= pontos;
                    end
                end

                FIM_JOGO: begin
                    // Cobrinha sem movimento
                    nivel_velocidade <= 3'd0;
                end

                default: begin
                    direcao_atual <= ESQ;
                end
            endcase
        end
    end

endmodule