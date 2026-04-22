module rom_background (
    input  wire [4:0] x_tile,        
    input  wire [4:0] y_tile,
    output wire [2:0] bg_color_palette
);

`ifndef SYNTHESIS
reg [2:0] storage [0:299];
`else
(* ram_init_file = "../Modulos/RawData/rom_background.mif" *)
reg [2:0] storage [0:299];
`endif

// Endereço na tela (0–299)
wire [8:0] addr;
assign addr = (y_tile << 4) + (y_tile << 2) + x_tile;

initial begin
    $readmemh("../Modulos/RawData/rom_background.mem", storage);
end

assign bg_color_palette = storage[addr];

endmodule
