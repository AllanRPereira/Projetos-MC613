module ram_oam (
    input wire clk,
    input wire reset,

    // Coordenada do Tile na tela (Tiles: 32x32)
    input wire [4:0] x_tile,
    input wire [4:0] y_tile,

    // Porto de leitura extra para busca de posições livres
    input wire [8:0] probe_addr,

    // Inputs para escrita
    input wire sig_write_ram,           // Write enable
    input wire [8:0] ram_addr,          // Posição na memória para escrita
    input wire [4:0] sprite_in,         // ID do Novo Sprite
    input wire limpa_total,

    output wire [4:0] id_sprite,        // Conexão com a ROM para obtenção do Sprite
    output wire [4:0] probe_id_sprite   // Leitura combinacional na posição probe_addr

);

// OAM Memory
// [ID_SPRITE]
//    5b
(* ramstyle = "logic" *)
reg [4:0] sprite_mem [0:299];       // Possíveis 300 Sprites na tela
reg [8:0] clear_index;
reg clearing_oam;

// Inicialização da Memória
integer i;
initial begin
    for (i = 0; i < 300; i = i + 1)
        sprite_mem[i] = 5'b00000;
    clear_index = 9'd0;
    clearing_oam = 1'b1;
end

wire [8:0] sprite_addr;
assign sprite_addr = (y_tile << 4) + (y_tile << 2) + x_tile; // y_tile * 20 + x_tile


always @(posedge clk) begin
    if (reset) begin
        clear_index <= 9'd0;
        clearing_oam <= 1'b1;
        sprite_mem[0] <= 5'b00000;
    end else if (limpa_total) begin
        clear_index <= 9'd0;
        clearing_oam <= 1'b1;
    end else if (clearing_oam) begin
        sprite_mem[clear_index] <= 5'b00000;
        if (clear_index == 9'd299) begin
            clearing_oam <= 1'b0;
        end else begin
            clear_index <= clear_index + 9'd1;
        end
    end else if (sig_write_ram) begin
        sprite_mem[ram_addr] <= sprite_in;
    end
end

// Aqui apenas fornecemos os 5 últimos bits para o id_sprite:
assign id_sprite = clearing_oam ? 5'b00000 : sprite_mem[sprite_addr];
assign probe_id_sprite = clearing_oam ? 5'b00000 : sprite_mem[probe_addr];

endmodule