module display_to_screen (
	input wire CLOCK_50,
	input wire KEY[0],
	output reg VGA_HS,
   output reg VGA_VS,
   output wire VGA_BLANK_N,
   output wire VGA_SYNC_N,
	output wire R,
	output wire G,
	output wire B
	);
	
wire [9:0] x_screen;
wire [9:0] y_screen;
wire [4:0] x_tile;
wire [4:0] y_tile;
wire [3:0] sprite_color;
wire [3:0] bg_color;

assign x_tile = x_screen[9:4];
assign y_tile = y_screen[9:4];

vga VGA(
	.pixel_clk(CLOCK_50),
	.reset(key[0]),
	.pixel_x(x_screen),
	.pixel_y(y_screen),
	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS)
	);

	
color_selector ColorSelector(
	.sprite_color_idx(sprite_color),
	.bg_color_idx(bg_color)
	.red(R),
	.green(G),
	.blue(B)
	);
	
rom_background BG_decoder(
	.x_tile(x_tile),
	.y_tile(y_tile),
	.bg_color_palette(bg_color)
	);
	

	
