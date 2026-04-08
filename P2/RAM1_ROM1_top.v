module ram1_rom1_top (
    input  wire        clk,
    input  wire [9:0]  x,
    input  wire [8:0]  y,
    output wire [7:0]  pixel
);

wire [7:0] bg_data;

// Simple sprite position (fixed for now)
wire [9:0] sprite_x = 200;
wire [8:0] sprite_y = 150;

wire transparency_en = 0;

// Background ROM
rom_background_1 bg_rom (
    .x(x),
    .y(y),
    .data_out(bg_data)
);

// Sprite unit
ram_sprite_1 sprite (
    .clk(clk),
    .x(x),
    .y(y),
    .sprite_x(sprite_x),
    .sprite_y(sprite_y),
    .bg_data(bg_data),
    .transparency_en(transparency_en),
    .we(0),
    .write_addr(0),
    .data_in(0),
    .pixel_out(pixel)
);

endmodule