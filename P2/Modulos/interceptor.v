module interceptor(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [11:0] bitmap_sprite_palette,

    output reg [2:0] sprite_palette
);

    always @(*) begin
        // Um tile tem 32x32 pixels, sendo dividido em 4 quadrantes de 16x16.
        // O bit 4 de x e y nos diz em qual metade (0 a 15 ou 16 a 31) o pixel está.
        // x[4] == 0 -> Esquerda  | x[4] == 1 -> Direita
        // y[4] == 0 -> Cima      | y[4] == 1 -> Baixo

        case ({y[4], x[4]})
            2'b00: sprite_palette = bitmap_sprite_palette[11:9]; // Q1 (Quadrado Superior Esquerdo)
            2'b01: sprite_palette = bitmap_sprite_palette[8:6];  // Q2 (Quadrado Superior Direito)
            2'b10: sprite_palette = bitmap_sprite_palette[5:3];  // Q3 (Quadrado Inferior Esquerdo)
            2'b11: sprite_palette = bitmap_sprite_palette[2:0];  // Q4 (Quadrado Inferior Direito)
            default: sprite_palette = 3'b000;
        endcase
    end

endmodule


