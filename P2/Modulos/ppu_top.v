module ppu_top (
	input  wire CLOCK_50,               // clock de referência para o PLL
	input  wire [1:0] KEY,              // reset (ativo em nível alto)
    input  wire [3:0] SW,

	output wire [7:0] VGA_R,
	output wire [7:0] VGA_G,
	output wire [7:0] VGA_B,
	output wire VGA_HS,
	output wire VGA_VS,
	output wire VGA_BLANK_N,
	output wire VGA_SYNC_N,
	output wire VGA_CLK,
    output wire [1:0] LEDR
);

    wire pixel_clk;
	wire reset;
    assign reset = ~KEY[0];

    wire add_sprite_button;
    reg add_sprite_button_d;
    wire add_sprite_pulse;

    reg [8:0] sprite_write_addr;
    wire [4:0] sprite_to_add;

    reg [2:0] bg_override;

    // Conexões para escrita na memória RAM
	wire sig_write_ram;
	wire [8:0] ram_addr;
	wire [4:0] sprite_in;

    // Fios para conexão dos fios
	wire [9:0] pixel_x;
	wire [9:0] pixel_y;
	wire video_active;

    // Posições dos Tiles
    wire [4:0] x_tile;
    wire [4:0] y_tile;

    assign x_tile = pixel_x[9:5];
    assign y_tile = pixel_y[9:5];

    wire [4:0] id_sprite;
    wire [11:0] bitmap_sprite_palette;

    // Indice das cores na paleta
    wire [2:0] bg_color_palette;
    wire [2:0] sprite_palette;
    wire [2:0] bg_color_selected;

    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    assign add_sprite_button = ~KEY[1];
    assign add_sprite_pulse = add_sprite_button & ~add_sprite_button_d;
    assign sig_write_ram = add_sprite_pulse;
    assign ram_addr = sprite_write_addr;
    assign sprite_in = SW[3:0];
    assign sprite_to_add = SW[3:0];
    assign bg_color_selected = bg_color_palette + bg_override;
    assign LEDR[1] = add_sprite_button;


    pll pll_inst (
        .refclk(CLOCK_50),
        .rst(~KEY[0]),
        .outclk_0(pixel_clk),
        .locked(LEDR[0])
    );

    ram_oam RAM_OAM (
        .clk(pixel_clk),
        .x_tile(x_tile),
        .y_tile(y_tile),
        .sig_write_ram(sig_write_ram),
        .ram_addr(ram_addr),
        .sprite_in(sprite_in),
        .id_sprite(id_sprite)
    );

    rom_sprite ROM_SPRITE (
        .id_sprite(id_sprite),
        .bitmap_sprite_palette(bitmap_sprite_palette)
    );

    interceptor INTERCEPTOR (
        .x(pixel_x),
        .y(pixel_y),
        .bitmap_sprite_palette(bitmap_sprite_palette),
        .sprite_palette(sprite_palette)
    );

    rom_background ROM_BACKGROUND (
        .x_tile(x_tile),
        .y_tile(y_tile),
        .bg_color_palette(bg_color_palette)
    );

    color_selector COLOR_SELECTOR (
        .sprite_color_idx(sprite_palette),
        .bg_color_idx(bg_color_selected),
        .red(red),
        .green(green),
        .blue(blue)
    );

    VGA Display (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .r_in(red),
        .g_in(green),
        .b_in(blue),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    always @(posedge pixel_clk) begin
        if (reset) begin
            add_sprite_button_d <= 1'b0;
            sprite_write_addr <= 9'd0;
            bg_override <= 3'd0;
        end else begin
            add_sprite_button_d <= add_sprite_button;

            if (add_sprite_pulse) begin
                if (sprite_write_addr >= 9'd299)
                    sprite_write_addr <= 9'd0;
                else
                    sprite_write_addr <= sprite_write_addr + 9'd1;
            end

            bg_override <= SW[2:0];
        end
    end

    

endmodule
