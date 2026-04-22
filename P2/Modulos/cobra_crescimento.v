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

    // Informações da fruta
    input wire fruta_ativa,
    input wire [4:0] fruta_x_tile,
    input wire [4:0] fruta_y_tile,

    output reg comeu_fruta,
    output reg bateu_corpo,
    output reg bateu_parede,
    output reg cobra_cheia,

    // Sinais que irão para a OAM escrever novos sprites para a cobra
    output reg sig_write_ram,
    output reg [8:0] ram_addr,
    output reg [4:0] sprite_in,

    // Informações de onde estão a cabeça, cauda e tamanho da cobra (Endereços em Tiles)
    output reg [4:0] cabeca_x,
    output reg [4:0] cabeca_y,
    output reg [4:0] cauda_x,
    output reg [4:0] cauda_y,
    output reg [8:0] comprimento
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

    reg [9:0] corpo [0:MAX_SEGMENTOS-1];
    reg [1:0] fase_escrita;
    reg [8:0] novo_endereco_cabeca;
    reg [8:0] endereco_cabeca_antiga;
    reg [8:0] endereco_cauda_antiga;
    reg crescimento_ativo;
    reg escreve_corpo_antigo;
    reg [9:0] proxima_posicao_calculada;
    reg crescimento_evento;
    reg colide_com_corpo;
    reg colide_com_parede;

    integer i;

    // Junta as entradas x e y para ter o endereço completo na memória RAM do Tile
    function [9:0] empacota_posicao;
        input [4:0] pos_x;
        input [4:0] pos_y;
        begin
            empacota_posicao = {pos_x, pos_y};
        end
    endfunction


    // Obtém as posição x e y de uma coordenada no formato de tile
    function [4:0] pos_x;
        input [9:0] posicao;
        begin
            pos_x = posicao[9:5];
        end
    endfunction

    function [4:0] pos_y;
        input [9:0] posicao;
        begin
            pos_y = posicao[4:0];
        end
    endfunction

    // Calcula o endereço na memória RAM com base nas coordenadas do Tile
    function [8:0] calcula_endereco;
        input [4:0] pos_x_tile;
        input [4:0] pos_y_tile;
        begin
            calcula_endereco = (pos_y_tile << 4) + (pos_y_tile << 2) + pos_x_tile;
        end
    endfunction

    // Avalia qual será a próxima posição dependendo da direção e da posição atual
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
        colide_com_corpo = 1'b0;
        colide_com_parede = 1'b0;
        crescimento_evento = 1'b0;
        // corpo[0] é a posição da cabeça :D
        proxima_posicao_calculada = proxima_posicao(corpo[0], direcao_atual);

        if (estado_atual == MOVIMENTO && passo_movimento && fase_escrita == 2'd0) begin
            // Verifica se na próxima movimentação haverá um crescimento ativo da cobra
            crescimento_evento = fruta_ativa &&
                                  proxima_posicao_calculada[9:5] == fruta_x_tile &&
                                  proxima_posicao_calculada[4:0] == fruta_y_tile;
            
            // Essas posições estão corretas, servem como identificador de que saiu dos limites
            // da tela, como demonstrado na função proxima_posicao()
            if (proxima_posicao_calculada[9:5] == 5'd31 ||
                proxima_posicao_calculada[4:0] == 5'd31) begin
                colide_com_parede = 1'b1;
            end else begin
                // Avaliar essa situação do crescimento, precisa mesmo para o if true ?
                if (crescimento_evento) begin
                    for (i = 1; i < comprimento; i = i + 1) begin
                        if (corpo[i] == proxima_posicao_calculada)
                            colide_com_corpo = 1'b1;
                    end
                end else begin
                    for (i = 1; i + 1 < comprimento; i = i + 1) begin
                        if (corpo[i] == proxima_posicao_calculada)
                            colide_com_corpo = 1'b1;
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            // Informações de Reset da Cobra
            
            // Limpa o endereço de todas as partes da cobra
            for (i = 0; i < MAX_SEGMENTOS; i = i + 1) begin
                corpo[i] <= 10'd0;
            end
            // Endereço da parte 0 da cobra
            corpo[0] <= empacota_posicao(X_INICIAL, Y_INICIAL);
            comprimento <= 9'd1;
            // Cabeça e cauda no mesmo local
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
            sprite_in <= SPRITE_VAZIO;      // Apenas para não deixar vazio, não será usado

            fase_escrita <= 2'd0;
            crescimento_ativo <= 1'b0;
            novo_endereco_cabeca <= 9'd0;
            endereco_cauda_antiga <= 9'd0;
        end else begin
            // Variáveis de estado/identificação zeradas
            comeu_fruta <= 1'b0;
            bateu_corpo <= 1'b0;
            bateu_parede <= 1'b0;
            cobra_cheia <= 1'b0;
            sig_write_ram <= 1'b0;

            if (estado_atual == INICIAR) begin
                for (i = 0; i < MAX_SEGMENTOS; i = i + 1) begin
                    corpo[i] <= 10'd0;
                end
                corpo[0] <= empacota_posicao(X_INICIAL, Y_INICIAL);
                comprimento <= 9'd1;
                cabeca_x <= X_INICIAL;
                cabeca_y <= Y_INICIAL;
                cauda_x <= X_INICIAL;
                cauda_y <= Y_INICIAL;
                fase_escrita <= 2'd0;
                crescimento_ativo <= 1'b0;

            end else if (estado_atual == MOVIMENTO) begin
                // Avalie nesse bloco a situação da adição do novo script e o endereço dele
                if (fase_escrita == 2'd0 && passo_movimento) begin
                    if (colide_com_parede) begin
                        bateu_parede <= 1'b1;
                    end else if (colide_com_corpo) begin
                        bateu_corpo <= 1'b1;
                    end else begin
                        crescimento_ativo <= crescimento_evento;

                        if (crescimento_evento)
                            comeu_fruta <= 1'b1;

                        novo_endereco_cabeca <= calcula_endereco(
                            proxima_posicao_calculada[9:5],
                            proxima_posicao_calculada[4:0]
                        );

                        endereco_cabeca_antiga <= calcula_endereco(corpo[0][9:5], corpo[0][4:0]);

                        endereco_cauda_antiga <= calcula_endereco(corpo[comprimento-1][9:5], corpo[comprimento-1][4:0]);

                        escreve_corpo_antigo <= (comprimento > 9'd1) || crescimento_evento;
                        
                        // Dá para fazer esse bloco de uma forma mais otimizada 

                        // Esse bloco faz o ajuste das partes da cobra no array
                        if (crescimento_evento) begin
                            for (i = comprimento; i > 0; i = i - 1) begin
                                corpo[i] <= corpo[i - 1];
                            end
                            corpo[0] <= proxima_posicao_calculada;
                            comprimento <= comprimento + 9'd1;
                        end else begin
                            for (i = comprimento - 1; i > 0; i = i - 1) begin
                                corpo[i] <= corpo[i - 1];
                            end
                            corpo[0] <= proxima_posicao_calculada;
                        end

                        // Endereços atuais da cauda e cabeça
                        cabeca_x <= proxima_posicao_calculada[9:5];
                        cabeca_y <= proxima_posicao_calculada[4:0];
                        cauda_x <= corpo[comprimento - 1][9:5];
                        cauda_y <= corpo[comprimento - 1][4:0];

                        // Avaliação do tamanho máximo atingido
                        if ((crescimento_evento && (comprimento + 9'd1 == MAX_SEGMENTOS)) ||
                            (!crescimento_evento && (comprimento == MAX_SEGMENTOS))) begin
                            cobra_cheia <= 1'b1;
                        end

                        fase_escrita <= 2'd1;
                    end
                // Blocos abaixo realmente escrevem a informação na RAM após o próximo pulso de clock
                end else if (fase_escrita == 2'd1) begin
                    // Primeira escrita ne memória com a nova posição da cabeça
                    sig_write_ram <= 1'b1;
                    ram_addr <= novo_endereco_cabeca;
                    sprite_in <= SPRITE_CABECA;
                    fase_escrita <= 2'd2;
                end else if (fase_escrita == 2'd2) begin
                    // Segunda etapa de escrita, alteração do corpo antigo, ou remoção 
                    // de um sprite ativo da tela.
                    if (escreve_corpo_antigo) begin
                        sig_write_ram <= 1'b1;
                        ram_addr <= endereco_cabeca_antiga;
                        sprite_in <= SPRITE_CORPO;
                        fase_escrita <= crescimento_ativo ? 2'd0 : 2'd3;
                    end else begin
                        sig_write_ram <= 1'b1;
                        ram_addr <= endereco_cauda_antiga;
                        sprite_in <= SPRITE_VAZIO;
                        fase_escrita <= 2'd0;
                    end
                end else if (fase_escrita == 2'd3) begin
                    // Em caso de movimentação normal, o endereço da cauda antiga é preenchida com
                    // um sprite vazio
                    sig_write_ram <= 1'b1;
                    ram_addr <= endereco_cauda_antiga;
                    sprite_in <= SPRITE_VAZIO;
                    fase_escrita <= 2'd0;
                end
            end else if (estado_atual == FIM_JOGO || estado_atual == BATE_PAREDE || estado_atual == SE_MORDEU || estado_atual == VITORIA) begin
                fase_escrita <= 2'd0;
            end
        end
    end

endmodule
