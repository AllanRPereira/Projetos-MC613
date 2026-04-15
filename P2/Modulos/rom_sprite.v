module rom_sprite (
    input wire [4:0] id_sprite,                 // Identificador do Sprite
    output wire [11:0] bitmap_sprite_palette     // ID da cor em cada bloco do Sprite (4 Blocos 16x16)
);

// Memória para armazenar 32 possíveis sprites
// Cada com 4 seções de seleção de cor (3 bits para selecionar a cor na paleta (8 cores possíveis lá)): 
// | 1 | 2 |   
// | 3 | 4 |
//  Nessa ordem na memória!

reg [11:0] storage [0:31];

initial begin
    $readmemh("Modulos/sprites.mem", storage);
end

assign bitmap_sprite_palette = storage[id_sprite];

endmodule
