module ppu_top (
	input  wire CLOCK_50,               // clock de referência para o PLL
	input  wire [3:0] KEY,              // reset (ativo em nível alto)
    input  wire [3:0] SW,

	output wire [7:0] VGA_R,
	output wire [7:0] VGA_G,
	output wire [7:0] VGA_B,
	output wire VGA_HS,
	output wire VGA_VS,
	output wire VGA_BLANK_N,
	output wire VGA_SYNC_N,
	output wire VGA_CLK,
    output wire [1:0] LEDR
);

    wire pixel_clk;
	wire reset;
    assign reset = ~KEY[0];

    // Conexão para botões e chaves
    wire botao_confirmar;
    wire botao_esquerda;
    wire botao_direita;

    assign botao_confirmar = ~KEY[1];
    assign botao_esquerda = ~KEY[2];
    assign botao_direita = ~KEY[3];

    // Fios para conexão interna
	wire [9:0] pixel_x;
	wire [9:0] pixel_y;
	wire video_active;

    // Posições dos Tiles
    wire [4:0] x_tile;
    wire [4:0] y_tile;

    assign x_tile = pixel_x[9:5];
    assign y_tile = pixel_y[9:5];

    wire [4:0] id_sprite;
    wire [11:0] bitmap_sprite_palette;

    // Informações assíncronas da memória
    wire [8:0] probe_addr;
    wire [4:0] probe_id_sprite;

    // Indice das cores na paleta
    wire [2:0] bg_color_palette;
    wire [2:0] sprite_palette;
    wire [2:0] bg_color_selected;

    // Sinais para comunicação entre os módulos
    // Cobra_crescimento, Máquina Estados, Máquina de Controle
    wire [3:0] estado_atual;
    wire sig_fruta;
    wire sig_mordida;
    wire sig_5ms;
    wire sig_2s;
    wire sig_batida;
    wire sig_confirmar;
    wire sig_vel;
    wire sig_dir;
    wire sig_vit;
    wire passo_movimento;

    wire [1:0] direcao_atual;
    wire [7:0] frutas_comidas;
    wire [2:0] nivel_velocidade;
    wire [9:0] pontos;

    // Informações de estado da Cobra
    wire cobra_comeu_fruta;
    wire cobra_bateu_corpo;
    wire cobra_bateu_parede;
    wire cobra_cheia;
    wire cobra_sig_write_ram;
    wire [8:0] cobra_ram_addr;
    wire [4:0] cobra_sprite_in;
    wire [4:0] cobra_cabeca_x;
    wire [4:0] cobra_cabeca_y;
    wire [4:0] cobra_cauda_x;
    wire [4:0] cobra_cauda_y;
    wire [8:0] cobra_comprimento;

    // Informações e sinais da fruta
    wire fruta_ativa;
    wire fruta_sig_write_ram;
    wire [8:0] fruta_ram_addr;
    wire [4:0] fruta_sprite_in;
    wire [4:0] fruta_x_tile;
    wire [4:0] fruta_y_tile;

    // Sinais para comunicação com a memória RAM
    wire [8:0] ram_addr;
    wire [4:0] sprite_in;
    wire sig_write_ram;

    // Registradores para contadores de tempo específicos
    reg [18:0] contador_5ms;
    reg [22:0] contador_100ms;
    reg [26:0] contador_2s;
    reg [4:0] contador_movimento;
    reg [2:0] nivel_velocidade_anterior;

    // Sinais de tempo personalizado com contadores
    reg pulso_5ms;
    reg pulso_100ms;
    reg pulso_2s;
    reg pulso_movimento;

    reg [2:0] bg_override;
    reg [2:0] bg_estado_offset;

    // Cores de saída para a VGA
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    localparam [4:0] SPRITE_CABECA = 5'd1;
    localparam [4:0] SPRITE_CORPO = 5'd3;
    localparam [4:0] SPRITE_FRUTA = 5'd2;

    // Lógica combinacional para as conexões
    assign bg_color_selected = bg_color_palette + bg_override + bg_estado_offset;
    assign LEDR[1] = estado_atual[0];

    // Cobra e fruta compartilham a RAM
    assign sig_write_ram = cobra_sig_write_ram | fruta_sig_write_ram;
    assign ram_addr = cobra_sig_write_ram ? cobra_ram_addr : fruta_ram_addr;
    assign sprite_in = cobra_sig_write_ram ? cobra_sprite_in : fruta_sprite_in;
    assign passo_movimento = pulso_movimento;

    // Função para cálculo do movimento da cobra com base no nível
    // A cada quantos pixel_clk ela irá mover um tile com base na velocidade
    function [4:0] intervalo_movimento;
        input [2:0] nivel;
        begin
            // Ajustar esses parâmetros para configurar a velocidade
            case (nivel)
                3'd0: intervalo_movimento = 5'd29;
                3'd1: intervalo_movimento = 5'd24;
                3'd2: intervalo_movimento = 5'd19;
                3'd3: intervalo_movimento = 5'd14;
                3'd4: intervalo_movimento = 5'd9;
                3'd5: intervalo_movimento = 5'd4;
                default: intervalo_movimento = 5'd4;
            endcase
        end
    endfunction


    pll pll_inst (
        .refclk(CLOCK_50),
        .rst(~KEY[0]),
        .outclk_0(pixel_clk),
        .locked(LEDR[0])
    );

    always @(posedge pixel_clk) begin
        if (reset) begin
            contador_5ms <= 19'd0;
            contador_100ms <= 23'd0;
            contador_2s <= 27'd0;
            contador_movimento <= 5'd0;
            nivel_velocidade_anterior <= 3'd0;
            pulso_5ms <= 1'b0;
            pulso_100ms <= 1'b0;
            pulso_2s <= 1'b0;
            pulso_movimento <= 1'b0;
        end else begin
            // Contadores, responsáveis por frações de tempo diferentes de 50Mhz
            pulso_5ms <= 1'b0;
            pulso_100ms <= 1'b0;
            pulso_2s <= 1'b0;
            pulso_movimento <= 1'b0;

            if (contador_5ms >= 19'd249999) begin
                contador_5ms <= 19'd0;
                pulso_5ms <= 1'b1;
            end else begin
                contador_5ms <= contador_5ms + 19'd1;
            end

            if (contador_100ms >= 23'd4999999) begin
                contador_100ms <= 23'd0;
                pulso_100ms <= 1'b1;
            end else begin
                contador_100ms <= contador_100ms + 23'd1;
            end

            if (contador_2s >= 27'd99999999) begin
                contador_2s <= 27'd0;
                pulso_2s <= 1'b1;
            end else begin
                contador_2s <= contador_2s + 27'd1;
            end

            // Lógica para lidar com a velocidade personalizada
            // Sem afetar as demais lógicas do sistema
            if (estado_atual != 4'd1) begin
                contador_movimento <= 5'd0;
                nivel_velocidade_anterior <= nivel_velocidade;
            end else begin
                if (nivel_velocidade != nivel_velocidade_anterior) begin
                    contador_movimento <= 5'd0;
                    nivel_velocidade_anterior <= nivel_velocidade;
                end

                if (pulso_5ms) begin
                    if (contador_movimento >= intervalo_movimento(nivel_velocidade)) begin
                        contador_movimento <= 5'd0;
                        pulso_movimento <= 1'b1;
                    end else begin
                        contador_movimento <= contador_movimento + 5'd1;
                    end
                end
            end
        end
    end

    maquina_estados FSM (
        .clk(pixel_clk),
        .reset(reset),
        .sig_fruta(sig_fruta),
        .sig_mordida(sig_mordida),
        .sig_5ms(sig_5ms),
        .sig_2s(sig_2s),
        .sig_batida(sig_batida),
        .sig_confirmar(sig_confirmar),
        .sig_vel(sig_vel),
        .sig_dir(sig_dir),
        .sig_vit(sig_vit),
        .estado_atual(estado_atual)
    );

    maquina_controle CONTROLE (
        .clk(pixel_clk),
        .reset(reset),
        .clk_5ms(pulso_5ms),
        .clk_100ms(pulso_100ms),
        .clk_2s(pulso_2s),
        .botao_confirmar(botao_confirmar),
        .botao_1(botao_esquerda),
        .botao_2(botao_direita),
        .estado_atual(estado_atual),
        .comeu_fruta(cobra_comeu_fruta),
        .bateu_corpo(cobra_bateu_corpo),
        .bateu_parede(cobra_bateu_parede),
        .cobra_cheia(cobra_cheia),
        .sig_fruta(sig_fruta),
        .sig_mordida(sig_mordida),
        .sig_5ms(sig_5ms),
        .sig_2s(sig_2s),
        .sig_batida(sig_batida),
        .sig_confirmar(sig_confirmar),
        .sig_vel(sig_vel),
        .sig_dir(sig_dir),
        .sig_vit(sig_vit),
        .direcao_atual(direcao_atual),
        .frutas_comidas(frutas_comidas),
        .nivel_velocidade(nivel_velocidade),
        .pontos(pontos)
    );

    fruta_controlador FRUTA (
        .clk(pixel_clk),
        .reset(reset),
        .estado_atual(estado_atual),
        .nova_fruta(cobra_comeu_fruta),
        .probe_id_sprite(probe_id_sprite),
        .probe_addr(probe_addr),
        .fruta_x_tile(fruta_x_tile),
        .fruta_y_tile(fruta_y_tile),
        .fruta_ativa(fruta_ativa),
        .sig_write_ram(fruta_sig_write_ram),
        .ram_addr(fruta_ram_addr),
        .sprite_in(fruta_sprite_in)
    );

    cobra_crescimento #(
        .SPRITE_CABECA(SPRITE_CABECA),
        .SPRITE_CORPO(SPRITE_CORPO),
        .SPRITE_VAZIO(5'd0)
    ) COBRA (
        .clk(pixel_clk),
        .reset(reset),
        .estado_atual(estado_atual),
        .passo_movimento(passo_movimento),
        .direcao_atual(direcao_atual),
        .fruta_ativa(fruta_ativa),
        .fruta_x_tile(fruta_x_tile),
        .fruta_y_tile(fruta_y_tile),
        .comeu_fruta(cobra_comeu_fruta),
        .bateu_corpo(cobra_bateu_corpo),
        .bateu_parede(cobra_bateu_parede),
        .cobra_cheia(cobra_cheia),
        .sig_write_ram(cobra_sig_write_ram),
        .ram_addr(cobra_ram_addr),
        .sprite_in(cobra_sprite_in),
        .cabeca_x(cobra_cabeca_x),
        .cabeca_y(cobra_cabeca_y),
        .cauda_x(cobra_cauda_x),
        .cauda_y(cobra_cauda_y),
        .comprimento(cobra_comprimento)
    );

    ram_oam RAM_OAM (
        .clk(pixel_clk),
        .x_tile(x_tile),
        .y_tile(y_tile),
        .probe_addr(probe_addr),
        .sig_write_ram(sig_write_ram),
        .ram_addr(ram_addr),
        .sprite_in(sprite_in),
        .id_sprite(id_sprite),
        .probe_id_sprite(probe_id_sprite)
    );

    rom_sprite ROM_SPRITE (
        .id_sprite(id_sprite),
        .bitmap_sprite_palette(bitmap_sprite_palette)
    );

    interceptor INTERCEPTOR (
        .x(pixel_x),
        .y(pixel_y),
        .bitmap_sprite_palette(bitmap_sprite_palette),
        .sprite_palette(sprite_palette)
    );

    rom_background ROM_BACKGROUND (
        .x_tile(x_tile),
        .y_tile(y_tile),
        .bg_color_palette(bg_color_palette)
    );

    color_selector COLOR_SELECTOR (
        .sprite_color_idx(sprite_palette),
        .bg_color_idx(bg_color_selected),
        .red(red),
        .green(green),
        .blue(blue)
    );

    VGA Display (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .r_in(red),
        .g_in(green),
        .b_in(blue),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    always @(posedge pixel_clk) begin
        if (reset) begin
            bg_override <= 3'd0;
            bg_estado_offset <= 3'd0;
        end else begin
            bg_override <= SW[3:1];

            case (estado_atual)
                4'd5,
                4'd6,
                4'd8: bg_estado_offset <= 3'd4;
                4'd7: bg_estado_offset <= 3'd2;
                default: bg_estado_offset <= 3'd0;
            endcase
        end
    end

    

endmodule
