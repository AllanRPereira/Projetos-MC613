module cobra_crescimento #(
    parameter integer MAX_SEGMENTOS = 300,
    parameter [4:0] SPRITE_CABECA = 5'd3,
    parameter [4:0] SPRITE_CORPO = 5'd1,
    parameter [4:0] SPRITE_VAZIO = 5'd0,
    parameter [4:0] X_INICIAL = 5'd0,
    parameter [4:0] Y_INICIAL = 5'd0,
    parameter [1:0] DIRECAO_INICIAL = 2'd0
)(
    input wire clk,
    input wire reset,
    input wire [3:0] estado_atual,
    input wire passo_movimento,
    input wire [1:0] direcao_atual,

    input wire fruta_ativa,
    input wire [4:0] fruta_x_tile,
    input wire [4:0] fruta_y_tile,

    output reg comeu_fruta,
    output reg bateu_corpo,
    output reg bateu_parede,
    output reg cobra_cheia,

    output reg sig_write_ram,
    output reg [8:0] ram_addr,
    output reg [4:0] sprite_in,

    output reg [4:0] cabeca_x,
    output reg [4:0] cabeca_y,
    output reg [4:0] cauda_x,
    output reg [4:0] cauda_y,
    output reg [8:0] comprimento
);

    localparam INICIAR      = 4'd0;
    localparam MOVIMENTO     = 4'd1;
    localparam AUMENTAR_VEL  = 4'd2;
    localparam COME_FRUTA    = 4'd3;
    localparam MUDAR_DIR     = 4'd4;
    localparam SE_MORDEU     = 4'd5;
    localparam BATE_PAREDE   = 4'd6;
    localparam VITORIA       = 4'd7;
    localparam FIM_JOGO      = 4'd8;

    reg [9:0] corpo [0:MAX_SEGMENTOS-1];
    reg ocupacao [0:MAX_SEGMENTOS-1];

    reg [8:0] indice_cabeca;
    reg [8:0] indice_cauda;
    reg [1:0] fase_escrita;

    reg [9:0] posicao_cabeca_atual;
    reg [9:0] posicao_cauda_atual;
    reg [9:0] posicao_cauda_proxima;
    reg [9:0] proxima_posicao_calculada;

    reg [8:0] endereco_proxima_cabeca;
    reg [8:0] endereco_cabeca_antiga;
    reg [8:0] endereco_cauda_atual;

    reg [8:0] indice_cabeca_proximo;
    reg [8:0] indice_cauda_proximo;

    reg crescimento_evento;
    reg crescimento_ativo;
    reg colide_com_corpo;
    reg colide_com_parede;

    integer i;

    function [9:0] empacota_posicao;
        input [4:0] pos_x;
        input [4:0] pos_y;
        begin
            empacota_posicao = {pos_x, pos_y};
        end
    endfunction

    function [8:0] calcula_endereco;
        input [4:0] pos_x_tile;
        input [4:0] pos_y_tile;
        begin
            calcula_endereco = (pos_y_tile << 4) + (pos_y_tile << 2) + pos_x_tile;
        end
    endfunction

    function [8:0] proximo_indice;
        input [8:0] indice;
        begin
            if (indice == MAX_SEGMENTOS - 1)
                proximo_indice = 9'd0;
            else
                proximo_indice = indice + 9'd1;
        end
    endfunction

    function [9:0] proxima_posicao;
        input [9:0] posicao_atual;
        input [1:0] direcao;
        reg [4:0] x_atual;
        reg [4:0] y_atual;
        reg [4:0] x_seguinte;
        reg [4:0] y_seguinte;
        begin
            x_atual = posicao_atual[9:5];
            y_atual = posicao_atual[4:0];
            x_seguinte = x_atual;
            y_seguinte = y_atual;

            case (direcao)
                2'd0: begin
                    if (x_atual > 0)
                        x_seguinte = x_atual - 5'd1;
                    else
                        x_seguinte = 5'd31;
                end
                2'd1: begin
                    if (x_atual < 5'd19)
                        x_seguinte = x_atual + 5'd1;
                    else
                        x_seguinte = 5'd31;
                end
                2'd2: begin
                    if (y_atual > 0)
                        y_seguinte = y_atual - 5'd1;
                    else
                        y_seguinte = 5'd31;
                end
                2'd3: begin
                    if (y_atual < 5'd14)
                        y_seguinte = y_atual + 5'd1;
                    else
                        y_seguinte = 5'd31;
                end
                default: begin
                    x_seguinte = x_atual;
                    y_seguinte = y_atual;
                end
            endcase

            proxima_posicao = {x_seguinte, y_seguinte};
        end
    endfunction

    always @(*) begin
        // Informações sobre a posição da cabeça e da cauda
        // Sistema circular com bitmap para as posições
        posicao_cabeca_atual = corpo[indice_cabeca];
        posicao_cauda_atual = corpo[indice_cauda];
        proxima_posicao_calculada = proxima_posicao(posicao_cabeca_atual, direcao_atual);
        endereco_proxima_cabeca = calcula_endereco(proxima_posicao_calculada[9:5], proxima_posicao_calculada[4:0]);
        endereco_cabeca_antiga = calcula_endereco(posicao_cabeca_atual[9:5], posicao_cabeca_atual[4:0]);
        endereco_cauda_atual = calcula_endereco(posicao_cauda_atual[9:5], posicao_cauda_atual[4:0]);

        crescimento_evento = 1'b0;
        colide_com_corpo = 1'b0;
        colide_com_parede = 1'b0;

        indice_cabeca_proximo = proximo_indice(indice_cabeca);

        if (estado_atual == MOVIMENTO && passo_movimento && fase_escrita == 2'd0) begin
            crescimento_evento = fruta_ativa &&
                                 (proxima_posicao_calculada[9:5] == fruta_x_tile) &&
                                 (proxima_posicao_calculada[4:0] == fruta_y_tile);

            if (proxima_posicao_calculada[9:5] == 5'd31 ||
                proxima_posicao_calculada[4:0] == 5'd31) begin
                colide_com_parede = 1'b1;
            end else if (!crescimento_evento) begin
                if (ocupacao[endereco_proxima_cabeca] &&            // Se não estiver ocupado e também não for igual (Tamanho 1)
                    (endereco_proxima_cabeca != endereco_cauda_atual)) begin
                    colide_com_corpo = 1'b1;
                end
            end
        end

        // Casos para o crescimento
        if (crescimento_evento) begin
            indice_cauda_proximo = indice_cauda;
            posicao_cauda_proxima = posicao_cauda_atual;
        end else if (comprimento == 9'd1) begin
            indice_cauda_proximo = indice_cabeca_proximo;
            posicao_cauda_proxima = proxima_posicao_calculada;
        end else begin
            indice_cauda_proximo = proximo_indice(indice_cauda);
            posicao_cauda_proxima = corpo[indice_cauda_proximo];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < MAX_SEGMENTOS; i = i + 1) begin
                corpo[i] <= 10'd0;
                ocupacao[i] <= 1'b0;
            end

            corpo[0] <= empacota_posicao(X_INICIAL, Y_INICIAL);
            ocupacao[calcula_endereco(X_INICIAL, Y_INICIAL)] <= 1'b1;
            indice_cabeca <= 9'd0;
            indice_cauda <= 9'd0;
            comprimento <= 9'd1;

            cabeca_x <= X_INICIAL;
            cabeca_y <= Y_INICIAL;
            cauda_x <= X_INICIAL;
            cauda_y <= Y_INICIAL;

            comeu_fruta <= 1'b0;
            bateu_corpo <= 1'b0;
            bateu_parede <= 1'b0;
            cobra_cheia <= 1'b0;
            sig_write_ram <= 1'b0;
            ram_addr <= 9'd0;
            sprite_in <= SPRITE_VAZIO;

            fase_escrita <= 2'd0;
            crescimento_ativo <= 1'b0;
        end else begin
            comeu_fruta <= 1'b0;
            bateu_corpo <= 1'b0;
            bateu_parede <= 1'b0;
            cobra_cheia <= 1'b0;
            sig_write_ram <= 1'b0;

            if (estado_atual == INICIAR) begin
                for (i = 0; i < MAX_SEGMENTOS; i = i + 1) begin
                    corpo[i] <= 10'd0;
                    ocupacao[i] <= 1'b0;
                end

                corpo[0] <= empacota_posicao(X_INICIAL, Y_INICIAL);
                ocupacao[calcula_endereco(X_INICIAL, Y_INICIAL)] <= 1'b1;
                indice_cabeca <= 9'd0;
                indice_cauda <= 9'd0;
                comprimento <= 9'd1;
                cabeca_x <= X_INICIAL;
                cabeca_y <= Y_INICIAL;
                cauda_x <= X_INICIAL;
                cauda_y <= Y_INICIAL;
                fase_escrita <= 2'd0;
                crescimento_ativo <= 1'b0;
            end else if (estado_atual == MOVIMENTO) begin
                if (fase_escrita == 2'd0 && passo_movimento) begin
                    if (colide_com_parede) begin
                        bateu_parede <= 1'b1;
                    end else if (colide_com_corpo) begin
                        bateu_corpo <= 1'b1;
                    end else begin
                        crescimento_ativo <= crescimento_evento;

                        if (crescimento_evento) begin
                            comeu_fruta <= 1'b1;
                        end

                        corpo[indice_cabeca_proximo] <= proxima_posicao_calculada;
                        ocupacao[endereco_proxima_cabeca] <= 1'b1;

                        if (!crescimento_evento) begin
                            ocupacao[endereco_cauda_atual] <= 1'b0;
                        end

                        indice_cabeca <= indice_cabeca_proximo;
                        indice_cauda <= indice_cauda_proximo;

                        if (crescimento_evento) begin
                            comprimento <= comprimento + 9'd1;
                        end

                        cabeca_x <= proxima_posicao_calculada[9:5];
                        cabeca_y <= proxima_posicao_calculada[4:0];
                        cauda_x <= posicao_cauda_proxima[9:5];
                        cauda_y <= posicao_cauda_proxima[4:0];

                        if ((crescimento_evento && (comprimento == MAX_SEGMENTOS - 9'd1)) ||
                            (!crescimento_evento && (comprimento == MAX_SEGMENTOS))) begin
                            cobra_cheia <= 1'b1;
                        end

                        fase_escrita <= 2'd1;
                    end
                end else if (fase_escrita == 2'd1) begin
                    // Fases de Escrita: Adição do sprite da cabeça

                    sig_write_ram <= 1'b1;
                    ram_addr <= endereco_proxima_cabeca;
                    sprite_in <= SPRITE_CABECA;
                    fase_escrita <= 2'd2;
                end else if (fase_escrita == 2'd2) begin
                    // Adição do sprite do corpo se for necessário (Comeu a fruta)
                    if (crescimento_ativo || (comprimento > 9'd1)) begin
                        sig_write_ram <= 1'b1;
                        ram_addr <= endereco_cabeca_antiga;
                        sprite_in <= SPRITE_CORPO;
                        fase_escrita <= crescimento_ativo ? 2'd0 : 2'd3;
                    end else begin
                        sig_write_ram <= 1'b1;
                        ram_addr <= endereco_cabeca_antiga;
                        sprite_in <= SPRITE_VAZIO;
                        fase_escrita <= 2'd0;
                    end
                end else if (fase_escrita == 2'd3) begin
                    // Adição do sprite vazio no caso em que comeu uma fruta ao final
                    sig_write_ram <= 1'b1;
                    ram_addr <= endereco_cauda_atual;
                    sprite_in <= SPRITE_VAZIO;
                    fase_escrita <= 2'd0;
                end
            end else if (estado_atual == FIM_JOGO ||
                         estado_atual == BATE_PAREDE ||
                         estado_atual == SE_MORDEU ||
                         estado_atual == VITORIA) begin
                fase_escrita <= 2'd0;
            end
        end
    end

endmodule
