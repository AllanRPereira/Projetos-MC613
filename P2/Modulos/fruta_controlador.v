module fruta_controlador #(
    parameter [4:0] SPRITE_FRUTA = 5'd2,
    parameter [4:0] X_MAX = 5'd19,
    parameter [4:0] Y_MAX = 5'd14
)(
    input wire clk,
    input wire reset,
    input wire [3:0] estado_atual,
    input wire nova_fruta,
    input wire [4:0] probe_id_sprite,

    output reg [8:0] probe_addr,

    // Sinais de saída que indicam a posição atual da fruta na tela
    output reg [4:0] fruta_x_tile,
    output reg [4:0] fruta_y_tile,
    output reg fruta_ativa,                 // Identifica se a fruta está ativa na tela

    output reg sig_write_ram,
    output reg [8:0] ram_addr,
    output reg [4:0] sprite_in
);

    localparam INICIAR     = 4'd0;
    localparam MOVIMENTO   = 4'd1;
    localparam AUMENTAR_VEL = 4'd2;
    localparam COME_FRUTA  = 4'd3;
    localparam MUDAR_DIR   = 4'd4;
    localparam SE_MORDEU   = 4'd5;
    localparam BATE_PAREDE = 4'd6;
    localparam VITORIA     = 4'd7;
    localparam FIM_JOGO    = 4'd8;

    // Endereços calculados de forma combinacional para adicionar uma nova fruta 
    // no pulso de clock (Sementes virando fruta!! :)
    reg [4:0] x_semente;
    reg [4:0] y_semente;
    reg busca_ativa;
    reg limpar_fruta_pendente;
    reg [8:0] endereco_candidato;
    reg [8:0] fruta_addr_atual;
    reg fruta_addr_valida;
    reg nova_fruta_d;

    wire nova_fruta_pulse;

    // Calcular o endereço na memória RAM de um tile
    function [8:0] calcula_endereco;
        input [4:0] x_tile;
        input [4:0] y_tile;
        begin
            calcula_endereco = (y_tile << 4) + (y_tile << 2) + x_tile;
        end
    endfunction

    assign nova_fruta_pulse = nova_fruta & ~nova_fruta_d;

    // Muda a semente em um padrão de +3 para o X até girar na tela
    function [4:0] avanca_x;
        input [4:0] x_atual;
        begin
            if (x_atual >= X_MAX - 5'd2)
                avanca_x = 5'd0;
            else
                avanca_x = x_atual + 5'd3;
        end
    endfunction

    // Muda a semente em um padrão de +2 para o Y até girar na tela
    function [4:0] avanca_y;
        input [4:0] y_atual;
        begin
            if (y_atual >= Y_MAX - 5'd2)
                avanca_y = 5'd0;
            else
                avanca_y = y_atual + 5'd2;
        end
    endfunction

    always @(*) begin
        // Obtém de forma combinacional o conteúdo que está na RAM no endereço prob_addr
        // obtido em probe_id_sprite
        endereco_candidato = calcula_endereco(x_semente, y_semente);
        probe_addr = endereco_candidato;
    end

    always @(posedge clk) begin
        if (reset) begin
            x_semente <= 5'd1;
            y_semente <= 5'd1;
            fruta_x_tile <= 5'd1;
            fruta_y_tile <= 5'd1;
            fruta_ativa <= 1'b0;
            busca_ativa <= 1'b0;
            limpar_fruta_pendente <= 1'b0;
            fruta_addr_atual <= 9'd0;
            fruta_addr_valida <= 1'b0;
            nova_fruta_d <= 1'b0;
            sig_write_ram <= 1'b0;
            ram_addr <= 9'd0;
            sprite_in <= SPRITE_FRUTA;
        end else begin
            nova_fruta_d <= nova_fruta;
            sig_write_ram <= 1'b0;

            if (estado_atual == INICIAR || estado_atual == FIM_JOGO) begin
                fruta_ativa <= 1'b0;
                busca_ativa <= 1'b0;
                limpar_fruta_pendente <= 1'b0;
                fruta_addr_atual <= 9'd0;
                fruta_addr_valida <= 1'b0;
                x_semente <= 5'd1;
                y_semente <= 5'd1;
            end else if (nova_fruta_pulse) begin
                fruta_ativa <= 1'b0;
                if (fruta_addr_valida) begin
                    limpar_fruta_pendente <= 1'b1;
                end
                busca_ativa <= 1'b0;
                fruta_addr_valida <= 1'b0;
            end

            if (limpar_fruta_pendente) begin
                sig_write_ram <= 1'b1;
                ram_addr <= fruta_addr_atual;
                sprite_in <= 5'd0;
                limpar_fruta_pendente <= 1'b0;
                busca_ativa <= 1'b1;
            end else if (busca_ativa) begin
                if (probe_id_sprite == 5'd0) begin
                    fruta_x_tile <= x_semente;
                    fruta_y_tile <= y_semente;
                    fruta_ativa <= 1'b1;
                    busca_ativa <= 1'b0;
                    fruta_addr_atual <= endereco_candidato;
                    fruta_addr_valida <= 1'b1;

                    sig_write_ram <= 1'b1;
                    ram_addr <= endereco_candidato;
                    sprite_in <= SPRITE_FRUTA;
                end else begin
                    // Vai tentando adicionar uma fruta num local onde não há
                    // sprite ativo! Pode ocasionalmente demorar no caso da tela estar muito
                    // cheia com a cobra
                    x_semente <= avanca_x(x_semente);
                    y_semente <= avanca_y(y_semente);
                end
            end else if ((estado_atual == MOVIMENTO) && !fruta_ativa && !limpar_fruta_pendente) begin
                busca_ativa <= 1'b1;
            end
        end
    end

endmodule
