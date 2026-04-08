module ppu (
    input wire clk,
    input wire reset,
    input wire [3:0] KEYS,
    input wire [9:0] SW,

    input wire [9:0] pixel_X,
    input wire [9:0] pixel_Y,
    input wire video_active,

    // Dentro de um tile especifico procura posicao
    input wire [4:0] head_snake_X,
    input wire [4:0] head_snake_Y,
    input wire [4:0] food_x,
    input wire [4:0] food_y,

    output reg [7:0] vermelho_saida,
    output reg [7:0] verde_saida,
    output reg [7:0] azul_saida
);

    reg [3:0] background_map [299:0];

    wire [4:0] pixel_atual_x = pixel_X[9:5];
    wire [4:0] pixel_atual_y = pixel_Y[9:5];

    wire [8:0] background_address = (pixel_atual_y * 20) + pixel_atual_x;
    wire [3:0] tile_atual_id = background_map[background_address]; 

// Verifica os primeiros 5 pixels para saber qual tile do background se refere


    always @(*) begin
        if (!video_active) begin
            vermelho_saida = 8'h00;
            verde_saida = 8'h00;
            azul_saida = 8'h00;
        end

        else begin
            if (pixel_atual_x == head_snake_X && pixel_atual_y == head_snake_Y) begin
                verde_saida = 8'hFF; // define a cor verde
                vermelho_saida = 8'h00;
                azul_saida = 8'h00;
            end

            else if (pixel_atual_x == food_x && pixel_atual_y == food_y) begin
                vermelho_saida = 8'hFF;// define a cor vermelha
                verde_saida = 8'h00;
                azul_saida = 8'h00;

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
                        azul_saida = 8'h33;
                        end // Chão (Azul escuro)
                endcase
            end
        end
    end

endmodule