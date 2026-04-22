module maquina_controle (
    input wire clk,
    input wire reset,
    input wire clk_5ms,
    input wire clk_100ms,
    input wire clk_2s,
    input wire botao_confirmar,
    input wire botao_1,
    input wire botao_2,
    input wire estado_atual,

    output wire sig_fruta,
    output wire sig_mordida,
    output wire sig_5ms,
    output wire sig_2s,
    output wire sig_batida,
    output wire sig_confirmar,
    output wire sig_vel,
    output wire sig_dir,
    output wire sig_vit
);


reg [1:0] direcao_atual;

localparam ESQ = 2'd0;
localparam DIR = 2'd1;
localparam CIMA = 2'd2;
localparam BAIXO = 2'd3;

assign sig_confirmar = botao_confirmar;
assign sig_5ms = clk_5ms;

// Bloco combinacional
always @(*) begin

end

// Bloco Sequencial
always @(posedge clk) begin

    case (estado_atual)
        INICIAR: begin
           direcao_atual <= DIR;
        end

        MOVIMENTO: begin
            
        end

        AUMENTAR_VEL: begin
            
        end

        COME_FRUTA: begin
           
        end

        MUDAR_DIR: begin
            
        end

        SE_MORDEU: begin
            
        end

        BATE_PAREDE: begin
           
        end

        VITORIA: begin
            
        end

        FIM_JOGO: begin
            
        end
    endcase

end




endmodule