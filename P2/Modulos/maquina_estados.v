module maquina_estados (
    input wire clk,
    input wire reset,
    
    // Entradas de controle (condições de transição)
    input wire sig_fruta,
    input wire sig_mordida,
    input wire sig_5ms,
    input wire sig_2s,
    input wire sig_batida,
    input wire sig_confirmar,
    input wire sig_vel,
    input wire sig_dir,
    input wire sig_vit,

    // Saída representando o estado (opcional, útil para debug ou controle de outros módulos)
    output reg [3:0] estado_atual
);

    // Definição dos estados usando localparam
    localparam INICIAR      = 4'd0;
    localparam MOVIMENTO    = 4'd1;
    localparam AUMENTAR_VEL = 4'd2;
    localparam COME_FRUTA   = 4'd3;
    localparam MUDAR_DIR    = 4'd4;
    localparam SE_MORDEU    = 4'd5;
    localparam BATE_PAREDE  = 4'd6;
    localparam VITORIA      = 4'd7;
    localparam FIM_JOGO     = 4'd8;

    reg [3:0] prox_estado;

    always @(posedge clk) begin
        if (reset) begin
            estado_atual <= INICIAR;
        end else begin
            estado_atual <= prox_estado;
        end
    end

    always @(*) begin
        // Valor padrão para evitar latches
        prox_estado = estado_atual;

        case (estado_atual)
            INICIAR: begin
                if (sig_confirmar) 
                    prox_estado = MOVIMENTO;
            end

            MOVIMENTO: begin
                // Pode variar dependendo da prioridade entre os estados
                if (sig_vit)
                    prox_estado = VITORIA;
                else if (sig_batida)
                    prox_estado = BATE_PAREDE;
                else if (sig_mordida)
                    prox_estado = SE_MORDEU;
                else if (sig_fruta)
                    prox_estado = COME_FRUTA;
                else if (sig_vel)
                    prox_estado = AUMENTAR_VEL;
            end

            AUMENTAR_VEL: begin
                if (sig_2s) 
                    prox_estado = MOVIMENTO;
            end

            COME_FRUTA: begin
                if (sig_5ms) 
                    prox_estado = MOVIMENTO;
            end

            SE_MORDEU: begin
                if (sig_2s) 
                    prox_estado = FIM_JOGO;
            end

            BATE_PAREDE: begin
                if (sig_2s) 
                    prox_estado = FIM_JOGO;
            end

            VITORIA: begin
                if (sig_2s) 
                    prox_estado = INICIAR;
            end

            FIM_JOGO: begin
                if (sig_confirmar) 
                    prox_estado = INICIAR;
            end

            default: prox_estado = INICIAR;
        endcase
    end

endmodule