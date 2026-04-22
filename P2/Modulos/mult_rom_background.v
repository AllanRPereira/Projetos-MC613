module rom_background (
    input  wire [4:0] x_tile,        
    input  wire [4:0] y_tile,
	 input wire [0:1] bg_selector,
    output wire [2:0] bg_color_palette
);

reg [2:0] BG_GAME [0:299];
reg [2:0] BG_START [0:299];
reg [2:0] BG_END [0:299];


// Endereço na tela (0–299)
wire [8:0] addr;
assign addr = tile_y << 4 + tile_y << 2 + tile_x;

initial begin
    $readmemh("rom_background.mem", BG_GAME);
	 $readmemh("rom_start.mem", BG_GAME);
	 $readmemh("rom_end.mem", BG_END);
end

assign bg_color_palette = (bg_selector == 2'b00) ? BG_START[addr] :
           (bg_selector == 2'b01) ? BG_GAME[addr] :
           (bg_selector == 2'b10) ? BG_END[addr] :
           1'b0;

endmodule
