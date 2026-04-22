module ram_oam (
    input wire clk,

    // Coordenada do Tile na tela (Tiles: 32x32)
    input wire [4:0] x_tile,
    input wire [4:0] y_tile,

    // Inputs para escrita
    input wire sig_write_ram,           // Write enable
    input wire [8:0] ram_addr,          // Posição na memória para escrita
    input wire [4:0] sprite_in,         // ID do Novo Sprite

    output wire [4:0] id_sprite     // Conexão com a ROM para obtenção do Sprite

);

// OAM Memory
// [ID_SPRITE]
//    5b
reg [4:0] sprite_mem [0:299];       // Possíveis 300 Sprites na tela

// Inicialização da Memória
integer i;
initial begin
    for (i = 0; i < 300; i = i + 1)
        sprite_mem[i] = 15'b000000000000000;
end

wire [8:0] sprite_addr;
assign sprite_addr = (y_tile << 4) + (y_tile << 2) + x_tile; // y_tile * 20 + x_tile


always @(posedge clk) begin
    if (sig_write_ram) begin
        sprite_mem[ram_addr] <= sprite_in;
    end
end

// Aqui apenas fornecemos os 5 últimos bits para o id_sprite:
assign id_sprite = sprite_mem[sprite_addr];

endmodule