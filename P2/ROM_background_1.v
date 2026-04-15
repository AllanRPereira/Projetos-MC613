//Background listrado
module rom (
    input  wire [9:0] x,        // 0–639
    input  wire [9:0] y,        // 0–479
    output wire [7:0] data_out
);

reg [7:0] storage [0:299];

// Tile coordinates
wire [4:0] tile_x;
wire [4:0] tile_y;

// Final address (0–299)
wire [8:0] addr;

// Divide by 32 using shift
assign tile_x = x >> 5;  // x / 32
assign tile_y = y >> 5;  // y / 32

// Map 2D → 1D
assign addr = tile_y * 20 + tile_x;

initial begin
    $readmemh("ROM_background_1.mem", storage);
end


assign data_out = storage[addr];

endmodule
