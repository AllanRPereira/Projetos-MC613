//Sprite (tile 3x3) passa pela tela
module ram_sprite_1 (
    input  wire        clk,

    // Screen coordinates
    input  wire [9:0]  x,
    input  wire [8:0]  y,

    // Sprite position
    input  wire [9:0]  sprite_x,
    input  wire [8:0]  sprite_y,

    // Background pixel
    input  wire [7:0]  bg_data,

    // Transparency control (GLOBAL)
    input  wire        transparency_en,

    // RAM write interface
    input  wire        we,  //write enable
    input  wire [3:0]  write_addr,
    input  wire [7:0]  data_in,

    // Final pixel
    output reg  [7:0]  pixel_out
);

integer i;
initial begin
    for (i = 0; i < 9; i = i + 1)
        sprite_mem[i] = 8'h00;
end

// SPRITE RAM (3x3)
reg [7:0] sprite_mem [0:8];

always @(posedge clk) begin
    if (we)
        sprite_mem[write_addr] <= data_in;
end


// ADDRESSING
wire in_sprite;

assign in_sprite =
    (x >= sprite_x) && (x < sprite_x + 96) &&
    (y >= sprite_y) && (y < sprite_y + 96);

wire [9:0] local_x = x - sprite_x;
wire [8:0] local_y = y - sprite_y;

wire [1:0] tile_x = local_x >> 5;
wire [1:0] tile_y = local_y >> 5;

wire [3:0] sprite_addr;
assign sprite_addr = (tile_y << 1) + tile_y + tile_x;

wire [7:0] sprite_data;
assign sprite_data = (in_sprite) ? sprite_mem[sprite_addr] : 8'h00;


// FINAL OUTPUT
always @(*) begin
    if (in_sprite) begin
        if (transparency_en)
            pixel_out = bg_data;      // sprite fully hidden
        else
            pixel_out = sprite_data; // sprite fully visible
    end else begin
        pixel_out = bg_data;
    end
end

endmodule