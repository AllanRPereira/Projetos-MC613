module ppu1 #(
    parameter SPRITES_num = 4
)(
    input wire clk,
    input wire reset,
    input wire [3:0] KEYS,
    input wire [9:0] SW,

    input wire [9:0] pixel_X,
    input wire [9:0] pixel_Y,
    input wire video_active,

    // Dentro de um tile especifico procura posicao dos sprites
    input wire oam_enable,                   // Habilita pra gravar na OAM
    input wire [3:0] oam_address,           // Endereço do sprite
    input wire [13:0] oam_id_posicao,        // [13:10]=ID, [9:5]=Pos X, [4:0]=Pos Y

    output reg [7:0] vermelho_saida,
    output reg [7:0] verde_saida,
    output reg [7:0] azul_saida
);

    // Lógica relacionada a pegar a memória do background e guardar o id

    reg [3:0] background_map [299:0];       // Guarda no id de 4 bits uma posicao do background
    reg [13:0] OAM [0:SPRITES_num-1];

    wire [4:0] pixel_atual_x = pixel_X[9:5];
    wire [4:0] pixel_atual_y = pixel_Y[9:5];

    wire [8:0] background_address = (pixel_atual_y * 20) + pixel_atual_x;
    wire [3:0] tile_atual_id = background_map[background_address]; 

    always @(posedge clk) begin
        if (oam_enable) begin
            OAM[oam_address] <= oam_id_posicao;
        end
    end


    reg tem_sprite;
    reg [3:0] sprite_id;
    integer i;

    always @(*) begin
        tem_sprite = 0;
        sprite_id = 4'd0;
        
        // Verifica em um looping para buscar se tem sprite
        for (i = SPRITES_num - 1; i >= 0; i = i - 1) begin
            // Compara o X e Y da OAM com o pixel atual do VGA
            if (OAM[i][9:5] == pixel_atual_x && OAM[i][4:0] == pixel_atual_y) begin
                tem_sprite = 1;
                sprite_id = OAM[i][13:10];  // Pega o ID do sprite
            end
        end
    end

// Verifica os primeiros 5 pixels para saber qual tile do background se refere

    always @(*) begin
        if (!video_active) begin
            vermelho_saida = 8'h00;
            verde_saida = 8'h00;
            azul_saida = 8'h00;
        end

        else begin
            if (tem_sprite) begin
                case (sprite_id)
                    4'd1: begin     // Cobra
                        verde_saida = 8'hFF;
                        vermelho_saida = 8'h00; 
                        azul_saida = 8'h00;
                    end
                    4'd2: begin // Comida
                        vermelho_saida = 8'hFF;
                        verde_saida = 8'h00;
                        azul_saida = 8'h00;
                    end
                    default: begin // Qualquer outro sprite (ex: Amarelo)
                        vermelho_saida = 8'hFF;
                        verde_saida = 8'hFF;
                        azul_saida = 8'h00;
                    end
                endcase
            end
    
            else begin
                case (tile_atual_id)
                    4'd1: begin
                        vermelho_saida = 8'h44;
                        verde_saida = 8'h44;
                        azul_saida = 8'h44;
                    end // Parede (Cinza)

                    default: begin
                        vermelho_saida = 8'h00;
                        verde_saida = 8'h00;
                        azul_saida = 8'h00;
                        end // Chão (Preto)
                endcase
            end
        end
    end

endmodule   