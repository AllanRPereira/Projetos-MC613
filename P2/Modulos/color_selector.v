module color_selector (
	input wire [2:0] sprite_color_idx,
	input wire [2:0] bg_color_idx,
	output wire [7:0] red,
	output wire [7:0] green,
	output wire [7:0] blue 
	);
	
wire [2:0] disp_color_idx;
wire [23:0] rgb;
reg [23:0] storage [0:7];

assign disp_color_idx = (sprite_color_idx > 0) ? sprite_color_idx : bg_color_idx;

initial begin
	$readmemh("RawData/palette.mem", storage);
end

assign rgb = storage[disp_color_idx];

assign red = rgb[23:16];
assign green = rgb[15:8];
assign blue = rgb[7:0];
	
endmodule
	